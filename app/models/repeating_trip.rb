class RepeatingTrip < ApplicationRecord
  include RequiredFieldValidatorModule
  include RecurringRideCoordinatorScheduler
  include RecurringRideCoordinator
  include TripCore
  include PublicActivity::Common

  has_paper_trail
  
  has_many :trips # Child trips created by this repeating trip's scheduler

  has_many :ridership_mobilities, class_name: "RepeatingTripRidershipMobility", foreign_key: :host_id, dependent: :destroy
  has_many :repeating_itineraries, dependent: :destroy

  has_one    :return_trip, class_name: "RepeatingTrip", foreign_key: :linking_trip_id
  belongs_to :outbound_trip, class_name: 'RepeatingTrip', foreign_key: :linking_trip_id

  schedules_occurrences_with with_attributes: -> (trip) {
      {
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
    },
    destroy_future_occurrences_with: -> (trip) {
      # Be sure not delete occurrences that have already happened.
      trips = if trip.pickup_time < Time.zone.now
        Trip.repeating_based_on(trip.repeating_trip).after_today.not_called_back
      else 
        Trip.repeating_based_on(trip.repeating_trip).after(trip.pickup_time).not_called_back
      end

      schedule = trip.repeating_trip.schedule
      Trip.transaction do
        trips.find_each do |t|
          t.destroy unless schedule.occurs_on?(t.pickup_time)
        end
      end
    },
    destroy_all_future_occurrences_with: -> (trip) {
      # Be sure not delete occurrences that have already happened.
      trips = if trip.pickup_time < Time.zone.now
        Trip.repeating_based_on(trip.repeating_trip).after_today.not_called_back
      else 
        Trip.repeating_based_on(trip.repeating_trip).after(trip.pickup_time).not_called_back
      end

      trips.destroy_all
    },
    unlink_past_occurrences_with: -> (trip) {
      if trip.pickup_time < Time.zone.now
        Trip.repeating_based_on(trip.repeating_trip).today_and_prior.update_all "repeating_trip_id = NULL"
      else 
        Trip.repeating_based_on(trip.repeating_trip).prior_to(trip.pickup_time).update_all "repeating_trip_id = NULL"
      end
    }

  belongs_to :driver, -> { with_deleted } 
  belongs_to :vehicle, -> { with_deleted }

  has_many :repeating_runs, through: :weekday_assignments
  has_many :weekday_assignments, dependent: :destroy

  validates :comments, :length => { :maximum => 30 } 
 
  scope :active, -> { where("end_date is NULL or end_date >= ?", Date.today) }
  
  def instantiate!
    return unless provider.try(:active?) && active? # Only build trips for active schedules

    # First and last days to create new trips
    now, later = scheduler_window_start, scheduler_window_end
    
    outbound_trip_id = self.linking_trip_id if self.is_return? 
    if outbound_trip_id
      outbound_daily_trips = Trip.for_date_range(now, later + 1.day).where(repeating_trip_id: outbound_trip_id).pluck("date(pickup_time)", :id).to_h
    end

    # Transaction block ensures that no DB changes will be made if there are any errors
    RepeatingTrip.transaction do
      # Potentially create a trip for each schedule occurrence in the scheduler window
      for date in schedule.occurrences_between(now, later)
        # Skip if occurrence is outside of schedule's active window
        next unless date_in_active_range?(date.to_date) && customer && !customer.deleted? && customer.active_for_date?(date)
        this_trip_pickup_time = Time.zone.local(date.year, date.month, date.day, pickup_time.hour, pickup_time.min, pickup_time.sec)
      
        # Build a trip belonging to the repeating trip for each schedule 
        # occurrence that doesn't already have a trip built for it.
        unless self.trips.for_date(date).exists?
          trip = Trip.new(
            self.attributes
              .select{ |k, v| (RepeatingTrip.ride_coordinator_attributes - ['repeating_run_id']).include?(k.to_s) }
              .merge( {
                "repeating_trip_id" => id,
                "pickup_time" => this_trip_pickup_time,
                "appointment_time" => appointment_time.present? ? (this_trip_pickup_time + (appointment_time - pickup_time)) : nil
              } )
          )  

          unless trip.valid?
            puts "invalid trip generated off recurring trip #{self.id}: #{trip.errors.full_messages.join('; ')}"
          end

          # find outbound instance
          unless outbound_daily_trips.blank?
            trip.linking_trip_id = outbound_daily_trips[date.to_date]
          end

          trip.save(validate: false)  #allow invalid trip exist
          
          self.ridership_mobilities.has_capacity.each do |m|
            trip.ridership_mobilities.create(capacity: m.capacity, ridership_id: m.ridership_id, mobility_id: m.mobility_id)
          end

          TrackerActionLog.create_trip(trip, nil)
        end
      end
      
      # Timestamp the scheduler to its current timestamp or the end of the
      # advance scheduling period, whichever comes last
      self.update_column :scheduled_through, [self.scheduled_through, later].compact.max
    end
  end

  def active?
    active = true

    today = Date.today
    active = false if end_date && today > end_date

    active
  end

  def clone_for_future!
    cloned_trip = self.dup
    
    cloned_trip.pickup_time = nil
    cloned_trip.appointment_time = nil
    cloned_trip.customer_informed = false
    cloned_trip.cab = false

    cloned_trip.ridership_mobilities = self.ridership_mobilities.has_capacity.collect{|m| m.dup}

    cloned_trip
  end

  def clone_for_return!(pickup_time_str = nil, appointment_time_str = nil)

    return_trip = self.dup 
    return_trip.direction = :return
    return_trip.pickup_address = self.dropoff_address
    return_trip.pickup_address_notes = self.dropoff_address_notes
    return_trip.dropoff_address = self.pickup_address
    return_trip.dropoff_address_notes = self.pickup_address_notes

    # assume pickup and appt time will be on that date
    return_trip.pickup_time = pickup_time_str
    return_trip.appointment_time = appointment_time_str

    return_trip.outbound_trip = self

    return_trip.ridership_mobilities = self.ridership_mobilities.has_capacity.collect{|m| m.dup}

    return_trip
  end

  def unschedule!
    weekday_assignments.each do |assignment|
      rr = assignment.repeating_run
      rr.delete_trip_manifest!(self.id, assignment.wday) if rr
    end
  end
end
