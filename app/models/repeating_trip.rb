# This is a 'dumb' model. It is managed by a Trip instance, which creates a 
# repeating instance of itself when instructed to. Validation is nonexistent 
# since all data should already have been vetted by the Trip instance.
class RepeatingTrip < ActiveRecord::Base
  include RequiredFieldValidatorModule
  include RecurringRideCoordinatorScheduler
  include RecurringRideCoordinator
  include TripCore

  has_paper_trail

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

  validates :comments, :length => { :maximum => 30 } 
 
  scope :active, -> { where("end_date is NULL or end_date >= ?", Date.today) }
  
  def instantiate!
    return unless active?

    now = Date.today.in_time_zone + 1.day
    later = now.advance(days: (provider.try(:advance_day_scheduling) || Provider::DEFAULT_ADVANCE_DAY_SCHEDULING) - 1)
    RepeatingTrip.transaction do
      for date in schedule.occurrences_between(now, later)
        date = date.to_date
        next if (start_date.present? && date < start_date) || (end_date.present? && date > end_date)
        this_trip_pickup_time = Time.zone.local(date.year, date.month, date.day, pickup_time.hour, pickup_time.min, pickup_time.sec)
      
        unless Trip.repeating_based_on(self).for_date(date).exists?
          # repeating_run_id is not part of trip attributes
          attributes = self.attributes.select{ |k, v| (RepeatingTrip.ride_coordinator_attributes - ['repeating_run_id']).include? k.to_s }
          attributes["repeating_trip_id"] = id
          attributes["pickup_time"] = this_trip_pickup_time
          attributes["appointment_time"] = this_trip_pickup_time + (appointment_time - pickup_time)
          trip = Trip.new attributes
          # no validation to allow creating individual instances despite some conflicts with other daily trips
          trip.save(validate: false)
        end
      end
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

    cloned_trip
  end
end
