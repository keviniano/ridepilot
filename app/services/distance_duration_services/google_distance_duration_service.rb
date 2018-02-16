class GoogleDistanceDurationService < AbstractDistanceDurationService
  TRIP_PLANNER_URL = ENV['GOOGLE_TRIP_PLANNER_URL']
  TRIP_PLANNER_KEY = ENV['GOOGLE_API_KEY']

  private

  def build_url
    url_options = "mode=driving"
    url_options += "&origins=#{@from_lat.to_s},#{@from_lon.to_s}"
    url_options += "&destinations=#{@to_lat.to_s},#{@to_lon.to_s}"
    # departure_time: in seconds  (only applicable if its current or future time)
    if @trip_datetime && @trip_datetime >= DateTime.now
      departure_time = @trip_datetime.to_i - DateTime.new(1970, 1, 1).to_i
      url_options += "&departure_time=#{departure_time}"
    end
    url_options += "&key=#{TRIP_PLANNER_KEY}"

    TRIP_PLANNER_URL + url_options
  end

  def parse_response(result)
    if result.has_key? 'error_message' and not result['error_message'].nil?
      Rails.logger.error "Service failure: #{result['error_message']}"
      return false, result['error_message']
    else
      return true, result['rows'].try(:first)
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
    response['elements'].try(:first) if response
  end

  def extract_duration(itinerary)
    itinerary['duration_in_traffic'].try(:[], 'value') || itinerary['duration'].try(:[], 'value') rescue nil
  end

  def extract_distance(itinerary)
    itinerary['distance']['value'] * METERS_TO_MILES rescue nil
  end

end
