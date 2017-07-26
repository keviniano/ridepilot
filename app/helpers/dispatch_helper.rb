module DispatchHelper

  def get_itineraries(run)
    return [] unless run

    itins = []

    run.trips.each do |trip|
      trip_data = {
        trip: trip,
        trip_id: trip.id,
        is_recurring: trip.repeating_trip_id.present?,
        customer: trip.customer.try(:name),
        phone: [trip.customer.phone_number_1, trip.customer.phone_number_2].compact,
        comments: trip.notes,
        result: trip.trip_result.try(:name) || 'Pending'
      }
      itins << trip_data.merge(
        id: "trip_#{trip.id}_leg_1",
        leg_flag: 1,
        time: trip.pickup_time,
        address: trip.pickup_address.try(:one_line_text)
      )
      itins << trip_data.merge(
        id: "trip_#{trip.id}_leg_2",
        leg_flag: 2,
        time: trip.appointment_time,
        address: trip.dropoff_address.try(:one_line_text)
      )
    end

    if run.manifest_order && run.manifest_order.any?
      itins.sort_by { |itin| run.manifest_order.index(itin[:id]) }
    else
      itins.sort_by { |itin| itin[:time] }
    end
  end

  def run_summary(run)
    if run
      trip_count = run.trips.count
      trips_part = if trip_count == 0
        "No trip" 
      elsif trip_count == 1
        "1 trip"
      else
        "#{trip_count} trips"
      end

      vehicle_part = "Vehicle: #{run.vehicle.try(:name) || (empty)}"
      driver_part = "Driver: #{run.driver.try(:name) || (empty)}"
      run_time_part = if !run.scheduled_start_time && !run.scheduled_end_time
        "Run time: (not specified)"
      else
        "Run Time: #{format_time_for_listing(run.scheduled_start_time)} - #{format_time_for_listing(run.scheduled_end_time)}"
      end
      
      [vehicle_part, driver_part, run_time_part, trips_part].join(', ')
    end
  end

end