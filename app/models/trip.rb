class Trip < ActiveRecord::Base
  include RequiredFieldValidatorModule
  include RecurringRideCoordinator

  acts_as_paranoid # soft delete
  
  schedules_occurrences_with :repeating_trip,
    with_attributes: -> (trip) {
      attrs = {}
      RepeatingTrip.ride_coordinator_attributes.each {|attr| attrs[attr] = trip.send(attr) }
      attrs['driver_id'] = trip.repetition_driver_id
      attrs['vehicle_id'] = trip.repetition_vehicle_id
      attrs['customer_informed'] = trip.repetition_customer_informed
      attrs['schedule_attributes'] = {
        repeat:        1,
        interval_unit: "week", 
        start_date:    trip.pickup_time.to_date.to_s,
        interval:      trip.repetition_interval, 
        monday:        trip.repeats_mondays    ? 1 : 0,
        tuesday:       trip.repeats_tuesdays   ? 1 : 0,
        wednesday:     trip.repeats_wednesdays ? 1 : 0,
        thursday:      trip.repeats_thursdays  ? 1 : 0,
        friday:        trip.repeats_fridays    ? 1 : 0,
        saturday:      trip.repeats_saturdays  ? 1 : 0,
        sunday:        trip.repeats_sundays    ? 1 : 0
      }
      attrs
    },
    destroy_future_occurrences_with: -> (trip) {
      # Be sure not delete occurrences that have already happened.
      if trip.pickup_time < Time.zone.now
        Trip.repeating_based_on(trip.repeating_trip).after_today.not_called_back.destroy_all
      else 
        Trip.repeating_based_on(trip.repeating_trip).after(trip.pickup_time).not_called_back.destroy_all
      end
    },
    unlink_past_occurrences_with: -> (trip) {
      if trip.pickup_time < Time.zone.now
        Trip.repeating_based_on(trip.repeating_trip).today_and_prior.update_all "repeating_trip_id = NULL"
      else 
        Trip.repeating_based_on(trip.repeating_trip).prior_to(trip.pickup_time).update_all "repeating_trip_id = NULL"
      end
    }

  has_paper_trail
  
  attr_accessor :driver_id, :vehicle_id

  belongs_to :called_back_by, class_name: "User"
  belongs_to :customer, inverse_of: :trips
  belongs_to :dropoff_address, class_name: "Address"
  belongs_to :funding_source
  belongs_to :mobility
  belongs_to :pickup_address, class_name: "Address"
  belongs_to :provider
  belongs_to :run
  belongs_to :service_level
  belongs_to :trip_purpose
  belongs_to :trip_result
  has_one    :donation
  has_one    :return_trip, class_name: "Trip", foreign_key: :linking_trip_id
  belongs_to :outbound_trip, class_name: 'Trip', foreign_key: :linking_trip_id


  delegate :label, to: :run, prefix: :run, allow_nil: true
  delegate :name, to: :customer, prefix: :customer, allow_nil: true
  delegate :name, to: :trip_purpose, prefix: :trip_purpose, allow_nil: true
  delegate :code, :name, to: :trip_result, prefix: :trip_result, allow_nil: true
  delegate :name, to: :service_level, prefix: :service_level, allow_nil: true

  # Trip is now manually assigned to a run via trips_runs controller
  # we dont need to compute or create a run when a new trip is created or updated
  #before_validation :compute_run
  
  serialize :guests

  validates :appointment_time, presence: true
  validates :attendant_count, numericality: {greater_than_or_equal_to: 0}
  validates :customer, associated: true, presence: true
  validates :dropoff_address, associated: true, presence: true
  validates :guest_count, numericality: {greater_than_or_equal_to: 0}
  validates :mileage, numericality: {greater_than: 0, allow_blank: true}
  validates :pickup_address, associated: true, presence: true
  validates :pickup_time, presence: true
  validates :trip_purpose_id, presence: true
  validates_datetime :appointment_time, presence: true
  validates_datetime :pickup_time, presence: true
  validate :driver_is_valid_for_vehicle
  validate :vehicle_has_open_seating_capacity
  validate :vehicle_has_mobility_device_capacity
  validate :completable_until_trip_appointment_time
  validate :provider_availability
  validates :mobility_device_accommodations, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
  validate :return_trip_later_than_outbound_trip
  validate :dropff_time_and_pickup_time_gap

  accepts_nested_attributes_for :customer

  scope :after,              -> (pickup_time) { where('trips.pickup_time > ?', pickup_time.utc) }
  scope :after_today,        -> { where('CAST(trips.pickup_time AS date) > ?', Date.today.in_time_zone.utc) }
  scope :by_funding_source,  -> (name) { includes(:funding_source).references(:funding_source).where("funding_sources.name = ?", name) }
  scope :by_result,          -> (code) { includes(:trip_result).references(:trip_result).where("trip_results.code = ?", code) }
  scope :by_service_level,   -> (level) { includes(:service_level).references(:service_level).where("service_levels.name = ?", level) }
  scope :by_trip_purpose,    -> (name) { includes(:trip_purpose).references(:trip_purpose).where("trip_purposes.name = ?", name) }
  scope :called_back,        -> { where('called_back_at IS NOT NULL') }
  scope :completed,          -> { Trip.by_result('COMP') }
  scope :during,             -> (pickup_time, appointment_time) { where('NOT ((trips.pickup_time < ? AND trips.appointment_time < ?) OR (trips.pickup_time > ? AND trips.appointment_time > ?))', pickup_time.utc, appointment_time.utc, pickup_time.utc, appointment_time.utc) }
  scope :for_cab,            -> { where(cab: true) }
  scope :for_date,           -> (date) { where('trips.pickup_time >= ? AND trips.pickup_time < ?', date.to_datetime.in_time_zone.utc, date.to_datetime.in_time_zone.utc + 1.day) }
  scope :for_date_range,     -> (start_date, end_date) { where('trips.pickup_time >= ? AND trips.pickup_time < ?', start_date.to_datetime.in_time_zone.utc, end_date.to_datetime.in_time_zone.utc) }
  scope :for_driver,         -> (driver_id) { not_for_cab.where(runs: {driver_id: driver_id}).joins(:run) }
  scope :for_provider,       -> (provider_id) { where(provider_id: provider_id) }
  scope :for_vehicle,        -> (vehicle_id) { not_for_cab.where(runs: {vehicle_id: vehicle_id}).joins(:run) }
  scope :has_scheduled_time, -> { where.not(pickup_time: nil).where.not(appointment_time: nil) }
  scope :incomplete,         -> { where(trip_result: nil) }
  scope :individual,         -> { joins(:customer).where(customers: {group: false}) }
  scope :not_called_back,    -> { where('called_back_at IS NULL') }
  scope :not_for_cab,        -> { where(cab: false) }
  scope :prior_to,           -> (pickup_time) { where('trips.pickup_time < ?', pickup_time.to_datetime.in_time_zone.utc) }
  scope :scheduled,          -> { includes(:trip_result).references(:trip_result).where("trips.trip_result_id is NULL or trip_results.code = 'COMP'") }
  scope :today_and_prior,    -> { where('CAST(trips.pickup_time AS date) <= ?', Date.today.in_time_zone.utc) }
  scope :turned_down,        -> { Trip.by_result('TD') }

  def date
    pickup_time.to_date
  end

  def complete
    trip_result.try(:code) == 'COMP'
  end

  def pending
    trip_result.blank?
  end

  def cancel!
    update_attributes( trip_result: TripResult.find_by_code('CANC') )
  end

  def vehicle_id
    run ? run.vehicle_id : @vehicle_id
  end

  def driver_id
    @driver_id || run.try(:driver_id)
  end
  
  def pickup_time=(datetime)
    write_attribute :pickup_time, format_datetime(datetime)
  end
  
  def appointment_time=(datetime)
    write_attribute :appointment_time, format_datetime(datetime)
  end

  def run_text
    if cab
      "Cab"
    elsif run
      run.label
    else
      "(No run specified)"
    end
  end
  
  def trip_size
    if customer.try(:group)
      group_size
    else 
      guest_count + attendant_count + 1
    end
  end

  def trip_count
    trip_size
  end

  def repetition_customer_informed=(value)
    @repetition_customer_informed = (value == "1" || value == true)
  end

  def repetition_customer_informed
    if @repetition_customer_informed.nil?
      @repetition_customer_informed = repeating_trip.try :customer_informed
    else
      @repetition_customer_informed
    end
  end

  def is_in_district?
    pickup_address.try(:in_district) && dropoff_address.try(:in_district)
  end

  def adjusted_run_id
    cab ? Run::CAB_RUN_ID : (run_id ? run_id : Run::UNSCHEDULED_RUN_ID)
  end

  def as_calendar_json
    return if appointment_time < pickup_time
    # if trip spans multiple day, should spit into several objects by each day
    common_data = {
      id: id,
      pickup_time: pickup_time.iso8601,
      appointment_time: appointment_time.iso8601,
      title: customer_name + "\n" + pickup_address.try(:address_text).to_s
    }

    if pickup_time.to_date == appointment_time.to_date
      common_data.merge({
        start: pickup_time.iso8601,
        "end": appointment_time.iso8601,
        resource: pickup_time.to_date.to_s(:js)
      })
    else
      start_time, end_time = pickup_time, appointment_time
      events = []
      while end_time.to_date != start_time.to_date
        new_event_data = common_data.dup
        events << new_event_data.merge({
          start: start_time.iso8601,
          "end": start_time.end_of_day.iso8601,
          resource: start_time.to_date.to_s(:js)
        })

        start_time = start_time.beginning_of_day + 1.day
      end

      if start_time <= appointment_time
        events << common_data.dup.merge({
          start: start_time.iso8601,
          "end": appointment_time.iso8601,
          resource: start_time.to_date.to_s(:js)
        })
      end
    end
  end
  
  def as_run_event_json
    return if appointment_time < pickup_time
    # run calendar requires start and end should be within one day
    end_time = appointment_time.to_date == pickup_time.to_date ? 
      appointment_time : pickup_time.end_of_day

    {
      id: id,
      pickup_time: pickup_time.iso8601,
      appointment_time: appointment_time.iso8601,
      start: pickup_time.iso8601,
      "end": end_time.iso8601,
      title: customer_name + "\n" + pickup_address.try(:address_text).to_s,
      resource: adjusted_run_id
    }
  end

  def update_donation(user, amount)
    return unless user && amount

    if self.donation
      self.donation.update_attributes(user: user, amount: amount)
    elsif self.id && self.customer
      self.donation = Donation.create(date: Time.now.in_time_zone, user: user, customer: self.customer, trip: self, amount: amount)
      self.save
    end
  end

  def is_no_show_or_turn_down?
    trip_result && ['NS', 'TD'].index(trip_result.code)
  end
    
  def clone_for_future!
    cloned_trip = self.dup
    
    cloned_trip.pickup_time = nil
    cloned_trip.appointment_time = nil
    cloned_trip.trip_result = nil
    cloned_trip.customer_informed = false
    cloned_trip.called_back_by = nil
    cloned_trip.donation = nil
    cloned_trip.run = nil
    cloned_trip.cab = false
    cloned_trip.repeating_trip = nil
    cloned_trip.drive_distance = nil

    cloned_trip
  end

  def clone_for_return!(pickup_time_str, appointment_time_str)
    return_trip = self.dup
    return_trip.direction = :return
    return_trip.pickup_address = self.dropoff_address
    return_trip.dropoff_address = self.pickup_address
    return_trip.pickup_time = nil
    return_trip.pickup_time = Time.zone.parse(pickup_time_str, self.pickup_time.beginning_of_day) if pickup_time_str
    return_trip.appointment_time = nil
    # assume same-day trip
    return_trip.appointment_time = Time.zone.parse(appointment_time_str, self.pickup_time.beginning_of_day) if appointment_time_str
    return_trip.outbound_trip = self
    return_trip.drive_distance = nil

    return_trip
  end

  def is_linked?
    (is_return? && outbound_trip) || (is_outbound? && return_trip)
  end

  def is_return?
    direction.try(:to_sym) == :return
  end

  def is_outbound?
    direction.try(:to_sym) == :outbound
  end

  def update_drive_distance!
    from_lat = pickup_address.try(:latitude)
    from_lon = pickup_address.try(:longitude)
    to_lat = dropoff_address.try(:latitude)
    to_lon = dropoff_address.try(:longitude)

    self.drive_distance = TripPlanner.new(from_lat, from_lon, to_lat, to_lon, pickup_time).get_drive_distance
    self.save
  end

  def as_profile_json
    {
      trip_id: id,
      pickup_time: pickup_time.try(:iso8601),
      dropff_time: appointment_time.try(:iso8601),
      comments: notes,
      status: status_json
    }
  end

  def status_json
    if trip_result
      code = trip_result.code
      name = trip_result.name
      message = trip_result.full_description
    elsif run
      code = :scheduled
      name = 'Scheduled'
      message = TranslationEngine.translate_text(:trip_has_been_scheduled)
    elsif cab
      code = :scheduled_to_cab
      name = 'Scheduled to Cab'
      message = TranslationEngine.translate_text(:trip_has_been_scheduled_to_cab)
    else  
      code = :requested
      name = 'Requested'
      message = TranslationEngine.translate_text(:trip_has_been_requested)
    end

    {
      code: code,
      name: name,
      message: message
    }
  end

  # potentially support multi-leg trips
  # need revisit when multi-leg is supported as direction field needs to be refactored
  def self.parse_leg_as_direction(leg)
    if leg.try(:to_s) == '2'
      :return
    else
      :outbound
    end
  end

  private
  
  def driver_is_valid_for_vehicle
    # This will error if a run was found or extended for this vehicle and time, 
    # but the driver for the run is not the driver selected for the trip
    if self.run.try(:driver_id).present? && self.driver_id.present? && self.run.driver_id.to_i != self.driver_id.to_i
      errors.add(:driver_id, TranslationEngine.translate_text(:driver_is_valid_for_vehicle_validation_error))
    end
  end

  # Check if the run's vehicle has open capacity at the time of this trip
  def vehicle_has_open_seating_capacity
    if run.try(:vehicle_id).present? && pickup_time.present? && appointment_time.present?
      vehicle_open_seating_capacity = run.vehicle.try(:open_seating_capacity, pickup_time, appointment_time, ignore: self)
      no_enough_capacity = !vehicle_open_seating_capacity ||  vehicle_open_seating_capacity < trip_size
      errors.add(:base, TranslationEngine.translate_text(:vehicle_has_open_seating_capacity_validation_error)) if no_enough_capacity
    end
  end

  # Check if the run's vehicle has enough mobility accommodations at the time of this trip
  def vehicle_has_mobility_device_capacity
    if mobility_device_accommodations && run.try(:vehicle_id).present? && pickup_time.present? && appointment_time.present?
      vehicle_mobility_capacity = run.vehicle.try(:open_mobility_device_capacity, pickup_time, appointment_time, ignore: self)
      no_enough_capacity = !vehicle_mobility_capacity ||  vehicle_mobility_capacity < mobility_device_accommodations
      errors.add(:base, TranslationEngine.translate_text(:vehicle_has_mobility_device_capacity_validation_error)) if no_enough_capacity
    end
  end

  # Can only allow to set trip as complete until day of the trip
  def completable_until_trip_appointment_time
    if complete && Time.current < appointment_time.in_time_zone
      errors.add(:base, TranslationEngine.translate_text(:completable_until_trip_appointment_time_validation_error))
    end
  end

  def provider_availability
    if pickup_time && provider && !provider.available?(pickup_time.wday, pickup_time.strftime('%H:%M'))
      errors.add(:base, TranslationEngine.translate_text(:provider_not_available_for_trip))
    end
  end

  def return_trip_later_than_outbound_trip
    if is_linked?
      if is_outbound? && appointment_time
        errors.add(:base, TranslationEngine.translate_text(:outbound_trip_dropoff_time_no_later_than_return_trip_pickup_time)) if appointment_time > return_trip.pickup_time
      elsif is_return? && pickup_time
        errors.add(:base, TranslationEngine.translate_text(:return_trip_pickup_time_no_earlier_than_outbound_trip_dropoff_time)) if pickup_time < outbound_trip.appointment_time
      end
    end
  end

  def dropff_time_and_pickup_time_gap
    time_gap_in_mins = (appointment_time - pickup_time) / 60 if appointment_time && pickup_time
    errors.add(:base, TranslationEngine.translate_text(:violate_provider_min_time_gap)) if provider && time_gap_in_mins && (time_gap_in_mins < provider.min_trip_time_gap_in_mins)
  end

  def compute_run    
    return true if run_id || cab || vehicle_id.blank? || provider_id.blank?

    if !pickup_time or !appointment_time 
      return true # we'll error out in validation
    end

    Trip.transaction do
      # When the trip is saved, we need to find or create a run for it. This 
      # will depend on the driver and vehicle.  
      self.run = Run.where("scheduled_start_time <= ? and scheduled_end_time >= ? and vehicle_id=? and provider_id=?", pickup_time, appointment_time, vehicle_id, provider_id).first

      if run.nil?
        # Find the next/previous runs for this vehicle and, if necessary, split 
        # or change times on them

        previous_run = Run.where("scheduled_start_time <= ? and vehicle_id=? and provider_id=? ", appointment_time, vehicle_id, provider_id).order("scheduled_start_time").last

        next_run = Run.where("scheduled_start_time >= ? and vehicle_id=? and provider_id=? ", pickup_time, vehicle_id, provider_id).order("scheduled_start_time").first

        # There are four possible cases: either the previous or the next run
        # could overlap the trip, or neither could.

        if previous_run and previous_run.scheduled_end_time > pickup_time
          # previous run overlaps trip
          if next_run and next_run.scheduled_start_time < appointment_time
            # Next run overlaps trip too
            return handle_overlapping_runs(previous_run, next_run)
          else
            # Just the previous run
            if previous_run.scheduled_start_time.to_date != pickup_time.to_date
              self.run = make_run
            else
              self.run = previous_run
              previous_run.update_attributes! scheduled_end_time: run.appointment_time
            end
          end
        else
          if next_run and next_run.scheduled_start_time < appointment_time
            # Just the next run
            if next_run.scheduled_start_time.to_date != pickup_time.to_date
              self.run = make_run
            else
              self.run = next_run
              next_run.update_attributes! scheduled_start_time: run.pickup_time
            end
          else
            # No overlap, create a new run
            self.run = make_run
          end
        end
      end
    end
  end

  def handle_overlapping_runs(previous_run, next_run)
    Trip.transaction do
      # Can we unify the runs?
      if next_run.driver_id == previous_run.driver_id
        self.run = unify_runs(previous_run, next_run)
        return
      end

      # Now, can we push the start of the second run later?
      first_trip = next_run.trips.first
      if first_trip.scheduled_start_time > appointment_time
        # Yes, we can
        next_run.update_attributes! scheduled_start_time: appointment_time
        previous_run.update_attributes! scheduled_end_time: appointment_time
        self.run = previous_run
      else
        # No, the second run is fixed. Can we push the end of the first run 
        # earlier?
        last_trip = previous_run.trips.last
        if last_trip.scheduled_end_time <= pickup_time
          # Yes, we can
          previous_run.update_attributes! scheduled_end_time: pickup_time
          next_run.update_attributes! scheduled_start_time: appointment_time
          self.run = next_run
        else
          return false
        end
      end
    end
  end

  def unify_runs(before, after)
    Trip.transaction do
      before.update_attributes! scheduled_end_time: after.scheduled_end_time, end_odometer: after.end_odometer
      for trip in after.trips
        trip.run = before
      end
      after.destroy
    end
    return before
  end

  def make_run
    Run.create!({
      provider_id:          provider_id,
      date:                 pickup_time.to_date,
      scheduled_start_time: Time.zone.local(
        pickup_time.year,
        pickup_time.month,
        pickup_time.day,
        BUSINESS_HOURS[:start],
        0, 0
      ),
      scheduled_end_time:   Time.zone.local(
        pickup_time.year,
        pickup_time.month,
        pickup_time.day,
        BUSINESS_HOURS[:end],
        0, 0
      ),
      vehicle_id:           vehicle_id,
      driver_id:            driver_id,
      complete:             false,
      paid:                 true
    })
  end

  def format_datetime(datetime)
    if datetime.is_a?(String)
      begin
        Time.zone.parse(datetime.gsub(/\b(a|p)\b/i, '\1m').upcase)
      rescue 
        nil
      end
    else
      datetime
    end
  end
end
