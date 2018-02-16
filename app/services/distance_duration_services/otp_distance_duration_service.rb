class OtpDistanceDurationService < AbstractDistanceDurationService
  
  TRIP_PLANNER_URL = ENV['OPEN_TRIP_PLANNER_URL']

  private

  def build_url
    time = @trip_datetime.strftime("%-I:%M%p")
    date = @trip_datetime.strftime("%Y-%m-%d")

    url_options = "mode=CAR"
    url_options += "&date=#{date}"
    url_options += "&time=#{time}"
    url_options += "&fromPlace=#{@from_lat.to_s},#{@from_lon.to_s}" 
    url_options += "&toPlace=#{@to_lat.to_s},#{@to_lon.to_s}"

    TRIP_PLANNER_URL + url_options
  end

  def parse_response(result)
    if result.has_key? 'error' and not result['error'].nil?
      Rails.logger.error "Service failure: fixed: result has error: #{result['error']}"
      return false, result['error']
    else
      return true, result['plan']
    end
  end

  # in seconds
  def parse_drive_time(response)
    itinerary = get_itinerary(response)
    
    extract_duration(itinerary)
  end

  # in miles
  def parse_drive_distance(response)
    itinerary = get_itinerary(response)
    
    extract_distance(itinerary)
  end

  def parse_driver_dist_and_duration(response)
    itinerary = get_itinerary(response)

    {
      distance: extract_distance(itinerary),
      duration: extract_duration(itinerary)
    }

  end

  def get_itinerary(response)
    response['itineraries'].try(:first) if response
  end

  def extract_duration(itinerary)
    itinerary['duration'] rescue nil
  end

  def extract_distance(itinerary)
    itinerary['legs'].first['distance'] * METERS_TO_MILES rescue nil
  end

end
