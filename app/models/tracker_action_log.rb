# a wrapper over public_activity gem
class TrackerActionLog < PublicActivity::Activity

  scope :for, -> (trackable) { where(trackable: trackable) }

  def self.create_return_trip(return_trip, user)
    if return_trip
      return_trip.create_activity :return_created, owner: user 
      outbound_trip = return_trip.outbound_trip
      outbound_trip.create_activity :create_return, owner: user if outbound_trip
    end
  end

  def self.cancel_or_turn_down_trip(trip, user)
    if trip && trip.is_cancelled_or_turned_down?
      action = trip.trip_result.turned_down? ? :trip_turned_down : :trip_cancelled
      trip.create_activity action, owner: user, params: {
        trip_result: trip.trip_result.try(:name), 
        reason: trip.result_reason
      }
    end
  end

  def self.create_subscription_trip(trip, user)
    if trip 
      trip.create_activity :subscription_created, owner: user
    end
  end

  def self.update_subscription_trip(trip, user, changes, previous_schedule = nil)
    if trip
      params = {}
      changes.each do |k, change|
        case k
        when 'pickup_time'
          if !compare_time_only(change[0], change[1])
            params["Pickup Time"] = [change[0].try(:strftime,'%I:%M%P'), trip.pickup_time.strftime('%I:%M%P')]
          end
        when 'appointment_time'
          params["Appointment Time"] = [change[0].try(:strftime,'%I:%M%P'), trip.appointment_time.strftime('%I:%M%P')] if !compare_time_only(change[0], change[1])
        when 'pickup_address_id'
          old_address = Address.find_by_id(change[0])
          new_address = trip.pickup_address
          params["Pickup Address"] = [old_address.try(:address_text), new_address.try(:address_text)]
        when 'dropoff_address_id'
          old_address = Address.find_by_id(change[0])
          new_address = trip.dropoff_address
          params["Dropoff Address"] = [old_address.try(:address_text), new_address.try(:address_text)]
        when 'customer_id'
          old_customer = Customer.find_by_id(change[0])
          new_customer = trip.customer
          params["Customer"] = [old_customer.try(:name), new_customer.try(:name)] 
        when 'trip_purpose_id'
          old_purpose = TripPurpose.find_by_id(change[0])
          new_purpose = trip.trip_purpose
          params["Trip Purpose"] = [old_purpose.try(:name), new_purpose.try(:name)]
        when 'mobility_id'
          old_mobility = Mobility.find_by_id(change[0])
          new_mobility = trip.mobility
          params["Mobility"] = [old_mobility.try(:name), new_mobility.try(:name)]
        when 'guest_count'
          params["Guests"] = change
        when 'attendant_count'
          params["Attendants"] = change
        when 'group_size'
          params["Group Size"] = change
        when 'mobility_device_accommodations'
          params["Mobility Device Count"] = change
        when 'start_date'
          params["Start Date"] = [change[0].try(:strftime, "%B %d, %Y"), trip.start_date.try(:strftime, "%B %d, %Y")]
        when 'end_date'
          params["End Date"] = [change[0].try(:strftime, "%B %d, %Y"), trip.end_date.try(:strftime, "%B %d, %Y")]
        when 'schedule_yaml'
          params["Schedule"] = [previous_schedule.try(:to_s), trip.schedule.to_s]
        end
      end

      trip.create_activity :subscription_updated, owner: user, params: params unless params.blank?
    end
  end

  def self.create_subscription_run(run, user)
    if run 
      run.create_activity :subscription_created, owner: user
    end
  end

  def self.update_subscription_run(run, user, changes, previous_schedule = nil)
    if run
      params = {}
      changes.each do |k, change|
        case k
        when 'scheduled_start_time'
          params["Scheduled Start Time"] = [change[0].try(:strftime,'%I:%M%P'), run.scheduled_start_time.strftime('%I:%M%P')] if !compare_time_only(change[0], change[1])
        when 'scheduled_end_time'
          params["Scheduled End Time"] = [change[0].try(:strftime,'%I:%M%P'), run.scheduled_end_time.strftime('%I:%M%P')] if !compare_time_only(change[0], change[1])
        when 'vehicle_id'
          old_vehicle = Vehicle.find_by_id change[0]
          params["Vehicle"] = [old_vehicle.try(:name), run.vehicle.try(:name)] 
        when 'driver_id'
          old_driver = Driver.find_by_id change[0]
          params["Driver"] = [old_driver.try(:name), run.driver.try(:name)]
        when 'start_date'
          params["Start Date"] = [change[0].try(:strftime, "%B %d, %Y"), run.start_date.try(:strftime, "%B %d, %Y")]
        when 'end_date'
          params["End Date"] = [change[0].try(:strftime, "%B %d, %Y"), run.end_date.try(:strftime, "%B %d, %Y")]
        when 'schedule_yaml'
          params["Schedule"] = [previous_schedule.try(:to_s), run.schedule.to_s]
        end
      end

      run.create_activity :subscription_updated, owner: user, params: params unless params.blank?
    end
  end

  def self.change_vehicle_initial_mileage(vehicle, user, prev_mileage)
    if vehicle 
      vehicle.create_activity :initial_mileage_changed, owner: user, params: {
        mileage: [prev_mileage, vehicle.initial_mileage], 
        reason: vehicle.initial_mileage_change_reason
      }
    end
  end

  private

  def self.compare_time_only(time_1, time_2)
    time_1.utc.strftime( "%H%M%S%N" ) == time_2.utc.strftime( "%H%M%S%N" )
  end
end