class Trip < ActiveRecord::Base
  include RequiredFieldValidatorModule
  include TripCore

  acts_as_paranoid # soft delete

  has_paper_trail

  attr_accessor :driver_id, :vehicle_id   #,:date #Custom date setter and getter in trip_core.rb

  belongs_to :called_back_by, -> { with_deleted }, class_name: "User"
  belongs_to :run
  belongs_to :trip_result, -> { with_deleted }
  has_one    :return_trip, class_name: "Trip", foreign_key: :linking_trip_id
  belongs_to :outbound_trip, class_name: 'Trip', foreign_key: :linking_trip_id
  belongs_to :repeating_trip
  has_one    :donation


  delegate :label, to: :run, prefix: :run, allow_nil: true
  delegate :code, :name, to: :trip_result, prefix: :trip_result, allow_nil: true

  # Trip is now manually assigned to a run via trips_runs controller
  # we dont need to compute or create a run when a new trip is created or updated
  #before_validation :compute_run

  #serialize :guests


  validates :mileage, numericality: {greater_than: 0, allow_blank: true}
  validate :driver_is_valid_for_vehicle
  validate :vehicle_has_open_seating_capacity
  validate :vehicle_has_mobility_device_capacity
  validate :completable_until_trip_appointment_day
  validate :provider_availability
  validate :return_trip_later_than_outbound_trip
  validate :within_advance_day_scheduling

  scope :after,              -> (pickup_time) { where('pickup_time > ?', pickup_time.utc) }
  scope :after_today,        -> { where('CAST(pickup_time AS date) > ?', Date.today.in_time_zone.utc) }
  scope :today_and_prior,    -> { where('CAST(pickup_time AS date) <= ?', Date.today.in_time_zone.utc) }
  scope :prior_to_today,     -> { where('CAST(pickup_time AS date) < ?', Date.today.in_time_zone.utc) }
  scope :during,             -> (pickup_time, appointment_time) { where('NOT ((pickup_time < ? AND appointment_time < ?) OR (pickup_time > ? AND appointment_time > ?))', pickup_time.utc, appointment_time.utc, pickup_time.utc, appointment_time.utc) }
  scope :for_date,           ->(date) { where(pickup_time: date.beginning_of_day..date.end_of_day) }
  scope :for_date_range,     -> (from_date, to_date) { where(pickup_time: from_date.beginning_of_day..to_date.end_of_day) } 
  scope :prior_to,           -> (pickup_time) { where('pickup_time < ?', pickup_time.to_datetime.in_time_zone.utc) } 
  scope :has_scheduled_time, -> { where.not(pickup_time: nil).where.not(appointment_time: nil) }
  scope :by_result,          -> (code) { includes(:trip_result).references(:trip_result).where("trip_results.code = ?", code) }
  scope :called_back,        -> { where('called_back_at IS NOT NULL') }
  scope :completed,          -> { joins(:trip_result).where(trip_results: {code: 'COMP'}) }
  scope :for_cab,            -> { where(cab: true) }
  scope :not_for_cab,        -> { where(cab: false) }
  scope :for_driver,         -> (driver_id) { not_for_cab.where(runs: {driver_id: driver_id}).joins(:run) }
  scope :for_vehicle,        -> (vehicle_id) { not_for_cab.where(runs: {vehicle_id: vehicle_id}).joins(:run) }
  scope :incomplete,         -> { where(trip_result: nil) }
  scope :empty_or_completed, -> { includes(:trip_result).references(:trip_result).where("trips.trip_result_id is NULL or trip_results.code = 'COMP'") }
  scope :turned_down,        -> { joins(:trip_result).where(trip_results: {code: 'TD'}) }
  scope :standby,            -> { joins(:trip_result).where(trip_results: {code: 'STNBY'}) }
  scope :scheduled,          -> { where("cab = ? or run_id is not NULL", true) }
  scope :repeating_based_on, ->(scheduler) { where(repeating_trip_id: scheduler.try(:id)) }

  # List of attributes of which the change would affect the run
  ATTRIBUTES_CAN_DISRUPT_RUN = [
    'customer_id',
    'pickup_time',
    'appointment_time',
    'pickup_address_id',
    'dropoff_address_id',
    'mobility_id',
    'guest_count',
    'attendant_count',
    'group_size',
    'mobility_device_accommodations'
  ]

  def self.attributes_can_disrupt_run
    ATTRIBUTES_CAN_DISRUPT_RUN
  end

  # Special date attr_reader sends back pickup/appointment time date, or instance var if present
  def date
    return @date if @date
    return pickup_time.to_date if pickup_time
    return appointment_time.to_date if appointment_time
    return nil
  end

  # Special date attr_writer sets @date instance variable. Accepts a Date object or a date string
  # This date is used in setting pickup and appointment time attributes
  def date=(date)
    return false if date.blank?
    @date = Date.parse(date.to_s)
    # Refresh pickup and appointment time with new date
    self.pickup_time = pickup_time #unless pickup_time.to_date == @date
    self.appointment_time = appointment_time #unless appointment_time.to_date == @date
  end

  # Takes a time and a date object, and returns a time object on the passed Date
  def time_on_date(t, d)
    return nil unless t
    return t unless d
    t = t.to_time
    Time.zone.local(d.year, d.month, d.day, t.hour, t.min, 0) # parse as local time
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

  # When setting pickup_time, set with @date attribute if present
  def pickup_time=(datetime)
    write_attribute :pickup_time,
      time_on_date(format_datetime(datetime), date)
  end

  # When setting appointment_time, set with @date attribute if present
  def appointment_time=(datetime)
    write_attribute :appointment_time,
      time_on_date(format_datetime(datetime), date)
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

  # DEPRECATED
  def is_no_show_or_turn_down?
    trip_result && ['NS', 'TD'].index(trip_result.code)
  end

  # Is the trip result one of several "cancel-type" codes?
  def result_is_cancel_code?
    trip_result && trip_result.cancelled?
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
    cloned_trip.outbound_trip = nil
    cloned_trip.direction = :outbound

    cloned_trip
  end

  def clone_for_return!(pickup_time_str = nil, appointment_time_str = nil)

    return_trip = self.dup
    return_trip.direction = :return
    return_trip.pickup_address = self.dropoff_address
    return_trip.dropoff_address = self.pickup_address

    # Set date to outbound trip date, and assume pickup and appt time will be on that date
    return_trip.date = self.date
    return_trip.pickup_time = pickup_time_str
    return_trip.appointment_time = appointment_time_str

    return_trip.outbound_trip = self
    return_trip.repeating_trip = nil
    return_trip.drive_distance = nil
    return_trip.trip_result = nil
    return_trip
  end

  def clone_for_repeating_trip!
    daily_trip_clone = self.clone_for_future!
    repeating_trip = RepeatingTrip.new
    repeating_trip.attributes = daily_trip_clone.attributes.select{ |k, v| repeating_trip.attributes.keys.include? k.to_s }

    repeating_trip
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

  # Move past scheduled trips in Standby queue to Unmet Need
  def self.move_prior_standby_to_unmet!
    unmet = TripResult.find_by_code('UNMET')
    Trip.prior_to_today.scheduled.standby.update_all(trip_result_id: unmet.id) if unmet.present?
  end

  def scheduled?
    run.present? || cab
  end

  # check if any attribute change would disrupt a run
  def run_disrupted_by_trip_changes?
    disruption_attrs_changed = self.changes.keys & Trip.attributes_can_disrupt_run
    actual_changes = []

    if disruption_attrs_changed.any?
      actual_changes = disruption_attrs_changed
      # filter out the case when you changed a nil to 0, in this case, we don't think it's a change
      disruption_attrs_changed.each do |attr_key|
        prev_val = self.try("#{attr_key}_was")
        val = self.try(attr_key)
        next unless (prev_val.blank? || prev_val == 0) && (val.blank? || val == 0)
        actual_changes = actual_changes - [attr_key]
      end
    end

    actual_changes.any?
  end

  def unschedule_trip
    if self.run.present?
      self.run = nil
      self.save(validate: false)
    elsif provider && provider.cab_enabled? && self.cab
      self.cab = false
      self.save(validate: false)
    end
  end

  def update_donation(user, amount)
    return unless user && amount

    if self.donation
      self.donation.update_attributes(user: user, amount: amount)
    elsif self.id && self.customer
      self.donation = Donation.create(date: Time.current, user: user, customer: self.customer, trip: self, amount: amount)
      self.save
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
  def completable_until_trip_appointment_day
    if complete && Time.current < appointment_time.in_time_zone.beginning_of_day
      errors.add(:base, TranslationEngine.translate_text(:completable_until_trip_appointment_day_validation_error))
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
      if first_trip.pickup_time > appointment_time
        # Yes, we can
        next_run.update_attributes! scheduled_start_time: appointment_time
        previous_run.update_attributes! scheduled_end_time: appointment_time
        self.run = previous_run
      else
        # No, the second run is fixed. Can we push the end of the first run
        # earlier?
        last_trip = previous_run.trips.last
        if last_trip.appointment_time <= pickup_time
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

  # Formats a variety of inputs as a Time object, and catches errors.
  # If a time string (e.g. "10:00 AM") is sent along with a date param, will
  # create the time at the given date. Defaults to today.
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

  def within_advance_day_scheduling
    advance_day_scheduling = provider.try(:get_advance_day_scheduling)
    if date && advance_day_scheduling.present? && (date - Date.current).to_i > advance_day_scheduling
      errors.add(:date, TranslationEngine.translate_text(:beyond_advance_day_scheduling) % {advance_day_scheduling: advance_day_scheduling})
    end
  end

end
