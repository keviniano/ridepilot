module TrackerActionLogHelper
  def formulate_log_message(log)
    return nil unless log 

    case log.key
    when "trip.create_return"
      return_trip = log.trackable.try(:return_trip)
      if return_trip.present?
        "Return trip (#{link_to return_trip.id, return_trip}) created.".html_safe
      end
    when "trip.return_created"
      outbound_trip = log.trackable.try(:outbound_trip)
      if outbound_trip.present?
        "Return trip created for outbound trip (#{link_to outbound_trip.id, outbound_trip})".html_safe
      end
    when "trip.trip_cancelled"
      trip = log.trackable
      if trip.present?
        params = log.parameters || {}
        reason = params[:reason].blank? ? 'Not provided.' : params[:reason]
        "Trip was cancelled (#{params[:trip_result]}). <br>Reason: #{reason}".html_safe
      end
    when "trip.trip_turned_down"
      trip = log.trackable
      if trip.present?
        params = log.parameters || {}
        reason = params[:reason].blank? ? 'Not provided.' : params[:reason]
        "Trip was Turned Down. <br>Reason: #{reason}".html_safe
      end
    end
  end
end