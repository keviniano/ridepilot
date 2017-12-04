module AvailabilityHelper

  def get_availability_chart_ticks(interval_min = 30)
    min_hour = current_provider.driver_availability_min_hour || 6
    max_hour = current_provider.driver_availability_max_hour || 22

    # tick gaps
    tick_gap_hour = ((max_hour - min_hour) / 8.to_f).ceil
    interval_count = (max_hour - min_hour) * 60 / interval_min

    # get hour tick lines
    start_hour = min_hour
    ticks = []

    while start_hour < max_hour do
      tick = [start_hour]
      if (start_hour - min_hour) % tick_gap_hour == 0
        tick << format_hour_label(start_hour) 
      else
        tick << ""
      end

      start_hour += interval_min.to_f / 60

      ticks << tick
    end

    ticks
  end

  def format_hour_label(hour)
    if hour == 0 || hour == 24
      "12am"
    elsif hour == 12
      "12pm"
    else
      hour < 12 ? "#{hour.to_i}am" : "#{hour.to_i - 12}pm"
    end 
  end

end