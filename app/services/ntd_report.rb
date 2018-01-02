# NTD Report
# Modify an existing blank template

class NtdReport

  TEMPLATE_PATH = "#{Rails.root}/public/ntd_template.xlsx"
  
  attr_reader :workbook

  def initialize(provider, year, month)
    @provider = provider
    @year = year
    @month = month
    @start_date = Date.new(year, 1, 1)
    @end_date = Date.new(year, month, 1).at_end_of_month + 1.day
  end

  def export!
    @workbook = RubyXL::Parser.parse(TEMPLATE_PATH)
    @worksheet = @workbook[0] #first worksheet

    get_base_data

    process_periods_of_service
    process_year_month_headers
    process_operations
    process_miles_and_hours

    @workbook
  end

  def get_base_data
    # ntd_reportable runs
    @runs = Run.ntd_reportable.complete.for_provider(@provider.try(:id)).for_date_range(@start_date, @end_date)
    @weekday_runs = @runs.where("extract(dow from date) in (?)", (1..5).to_a)
    @sat_runs = @runs.where("extract(dow from date) = ?", 6)
    @sun_runs = @runs.where("extract(dow from date) = ?", 0)

    # ntd_reportable trips
    @trips = Trip.ntd_reportable.for_provider(@provider.try(:id)).completed.joins(:run).where("runs.complete = ?", true).for_date_range(@start_date, @end_date)
    @weekday_trips = @trips.where("extract(dow from pickup_time) in (?)", (1..5).to_a)
    @sat_trips = @trips.where("extract(dow from pickup_time) = ?", 6)
    @sun_trips = @trips.where("extract(dow from pickup_time) = ?", 0)

    # ntd_reportable vehicles
    @vehicles = Vehicle.ntd_reportable.for_provider(@provider.try(:id))
  end

  def process_periods_of_service
    @weekday_earliest_runs = @weekday_runs.where.not(scheduled_start_time_string: nil).group(:date).minimum(:scheduled_start_time_string)
    @worksheet[1][3].change_contents (get_average_time(@weekday_earliest_runs))
    @sat_earliest_runs = @sat_runs.where.not(scheduled_start_time_string: nil).group(:date).minimum(:scheduled_start_time_string)
    @worksheet[1][4].change_contents (get_average_time(@sat_earliest_runs))
    @sun_earliest_runs = @sun_runs.where.not(scheduled_start_time_string: nil).group(:date).minimum(:scheduled_start_time_string)
    @worksheet[1][5].change_contents (get_average_time(@sun_earliest_runs))

    @weekday_latest_runs = @weekday_runs.where.not(scheduled_end_time_string: nil).group(:date).maximum(:scheduled_end_time_string)
    @worksheet[2][3].change_contents (get_average_time(@weekday_latest_runs))
    @sat_latest_runs = @sat_runs.where.not(scheduled_end_time_string: nil).group(:date).maximum(:scheduled_end_time_string)
    @worksheet[2][4].change_contents (get_average_time(@sat_latest_runs))
    @sun_latest_runs = @sun_runs.where.not(scheduled_end_time_string: nil).group(:date).maximum(:scheduled_end_time_string)
    @worksheet[2][5].change_contents (get_average_time(@sun_latest_runs))
  end

  def process_year_month_headers
    # update row 4 with reporting year and month names
    @worksheet[4][3].change_contents @year

    (1..12).each do |m|
      @worksheet[4][m + 4].change_contents Date.new(@year, m, 1)
    end
    
  end

  def process_operations
    @num_max_operated_vehicles = @runs.group("extract(month from date)").count("distinct(vehicle_id)")

    @num_unlinked_passenger_weekday_trips = sum_monthly_trip_size @weekday_trips
    @num_unlinked_passenger_sat_trips = sum_monthly_trip_size @sat_trips
    @num_unlinked_passenger_sun_trips = sum_monthly_trip_size @sun_trips

    @days_operated_weekday = count_monthly_days_operated @weekday_runs
    @days_operated_sat = count_monthly_days_operated @sat_runs
    @days_operated_sun = count_monthly_days_operated @sun_runs

    (1..12).each do |m|
      # Vehicles operated in maximum service
      max_vehicles = @num_max_operated_vehicles[m.to_f]
      @worksheet[6][m + 4].change_value(max_vehicles) unless max_vehicles.nil?

      # Vehicles available in maximum service
      monthly_tracking = VehicleMonthlyTracking.where(provider_id: @provider.try(:id), year: @year, month: m).first
      @worksheet[7][m + 4].change_value(monthly_tracking.max_available_count) unless monthly_tracking.nil?

      # Unlinked passenger trips
      weekday_trip_size = @num_unlinked_passenger_weekday_trips[m.to_f]
      @worksheet[10][m + 4].change_value(weekday_trip_size) unless weekday_trip_size.nil?
      sat_trip_size = @num_unlinked_passenger_sat_trips[m.to_f]
      @worksheet[11][m + 4].change_value(sat_trip_size) unless sat_trip_size.nil?
      sun_trip_size = @num_unlinked_passenger_sun_trips[m.to_f]
      @worksheet[12][m + 4].change_value(sun_trip_size) unless sun_trip_size.nil?

      # # of days operated
      weekday_days = @days_operated_weekday[m.to_f]
      @worksheet[16][m + 4].change_value(weekday_days) unless weekday_days.nil?
      sat_days = @days_operated_sat[m.to_f]
      @worksheet[17][m + 4].change_value(sat_days) unless sat_days.nil?
      sun_days = @days_operated_sun[m.to_f]
      @worksheet[18][m + 4].change_value(sun_days) unless sun_days.nil?
    end
  end

  def process_miles_and_hours
    @total_miles_weekday = sum_monthly_total_miles @weekday_runs
    @total_miles_sat = sum_monthly_total_miles @sat_runs
    @total_miles_sun = sum_monthly_total_miles @sun_runs

    @revenue_miles_weekday = sum_monthly_revenue_miles @weekday_runs
    @revenue_miles_sat = sum_monthly_revenue_miles @sat_runs
    @revenue_miles_sun = sum_monthly_revenue_miles @sun_runs

    @passenger_miles_weekday = sum_monthly_passenger_miles @weekday_runs
    @passenger_miles_sat = sum_monthly_passenger_miles @sat_runs
    @passenger_miles_sun = sum_monthly_passenger_miles @sun_runs

    @total_hours_weekday = sum_monthly_total_hours @weekday_runs
    @total_hours_sat = sum_monthly_total_hours @sat_runs
    @total_hours_sun = sum_monthly_total_hours @sun_runs

    (1..12).each do |m|
      # Total Actual Miles
      total_miles_weekday = @total_miles_weekday[m.to_f]
      @worksheet[23][m + 4].change_value(total_miles_weekday) unless total_miles_weekday.nil?
      total_miles_sat = @total_miles_sat[m.to_f]
      @worksheet[24][m + 4].change_value(total_miles_sat) unless total_miles_sat.nil?
      total_miles_sun = @total_miles_sun[m.to_f]
      @worksheet[25][m + 4].change_value(total_miles_sun) unless total_miles_sun.nil?

      # Total Vehicle Revenue Miles
      revenue_miles_weekday = @revenue_miles_weekday[m.to_f]
      @worksheet[28][m + 4].change_value(revenue_miles_weekday) unless revenue_miles_weekday.nil?
      revenue_miles_sat = @revenue_miles_sat[m.to_f]
      @worksheet[29][m + 4].change_value(revenue_miles_sat) unless revenue_miles_sat.nil?
      revenue_miles_sun = @revenue_miles_sun[m.to_f]
      @worksheet[30][m + 4].change_value(revenue_miles_sun) unless revenue_miles_sun.nil?

      # Scheduled Revenue Miles: save as Total Vehicle Revenue Miles
      @worksheet[38][m + 4].change_value(revenue_miles_weekday) unless revenue_miles_weekday.nil?
      @worksheet[39][m + 4].change_value(revenue_miles_sat) unless revenue_miles_sat.nil?
      @worksheet[40][m + 4].change_value(revenue_miles_sun) unless revenue_miles_sun.nil?

      # Passenger Miles (Ops Research)
      passenger_miles_weekday = @passenger_miles_weekday[m.to_f]
      @worksheet[43][m + 4].change_value(passenger_miles_weekday) unless passenger_miles_weekday.nil?
      passenger_miles_sat = @passenger_miles_sat[m.to_f]
      @worksheet[44][m + 4].change_value(passenger_miles_sat) unless passenger_miles_sat.nil?
      passenger_miles_sun = @passenger_miles_sun[m.to_f]
      @worksheet[45][m + 4].change_value(passenger_miles_sun) unless passenger_miles_sun.nil?

      # Total Actual Hours
      total_hours_weekday = @total_hours_weekday[m.to_f]
      @worksheet[49][m + 4].change_value(total_hours_weekday) unless total_hours_weekday.nil?
      total_hours_sat = @total_hours_sat[m.to_f]
      @worksheet[50][m + 4].change_value(total_hours_sat) unless total_hours_sat.nil?
      total_hours_sun = @total_hours_sun[m.to_f]
      @worksheet[51][m + 4].change_value(total_hours_sun) unless total_hours_sun.nil?

      # Total Vehicle Revenue Hours: based on revenue_miles / total_miles ratio
      if total_miles_weekday && total_hours_weekday
        revenue_pct = revenue_miles_weekday / total_miles_weekday.to_f  
        revenue_hours_weekday = total_hours_weekday * revenue_pct
        @worksheet[54][m + 4].change_value(revenue_hours_weekday) unless revenue_hours_weekday.nil?
      end
      if total_miles_sat && total_hours_sat
        revenue_pct = revenue_miles_sat / total_miles_sat.to_f  
        revenue_hours_sat = total_hours_sat * revenue_pct
        @worksheet[55][m + 4].change_value(revenue_hours_sat) unless revenue_hours_sat.nil?
      end
      if total_miles_sun && total_hours_sun
        revenue_pct = revenue_miles_sun / total_miles_sun.to_f  
        revenue_hours_sun = total_hours_sun * revenue_pct
        @worksheet[56][m + 4].change_value(revenue_hours_sun) unless revenue_hours_sun.nil?
      end
    end
  end


  private 

  def get_average_time(times_by_date)
    day_count = times_by_date.count 
    if day_count == 0
      'N/A'
    else
      total_hours = total_mins = 0
      times_by_date.each do |date, time_str|
        time_parts = time_str.split(":")
        total_hours += time_parts[0].to_i
        total_mins += time_parts[1].to_i
      end

      sum_mins = total_hours * 60 + total_mins
      average_mins = sum_mins / day_count

      hour = average_mins / 60
      min = average_mins - hour * 60

      DateTime.new(@year, 1, 1, hour, min)
    end 
  end

  def sum_monthly_trip_size(trips)
    trips.group("extract(month from pickup_time)").sum("customer_space_count + guest_count + attendant_count")
  end

  def count_monthly_days_operated(runs)
    runs.group("extract(month from date)").count("distinct(date)")
  end

  def sum_monthly_total_miles(runs)
    runs.joins(:run_distance).group("extract(month from date)").sum("total_dist")
  end

  def sum_monthly_passenger_miles(runs)
    runs.joins(:run_distance).group("extract(month from date)").sum("passenger_miles")
  end

  def sum_monthly_total_hours(runs)
    # if actual hours provided, then use it, otherwise use scheduled run duration
    actual_hours = runs.where("actual_start_time is NOT NULL and actual_end_time is NOT NULL").group("extract(month from date)").sum("extract(epoch from (actual_end_time - actual_start_time))")
    sche_hours = runs.where.not("actual_start_time is NOT NULL and actual_end_time is NOT NULL").group("extract(month from date)").sum("extract(epoch from (scheduled_end_time - scheduled_start_time))")

    # need to transform seconds to hours
    actual_hours.merge(sche_hours){ |k, a_value, b_value| (a_value + b_value)}.each_with_object({}) { |(key, value), hash| hash[key] = (value || 0) / 3600.0 }
  end

  def sum_monthly_revenue_miles(runs)
    # NTD algorithum: include the miles from the first pickup to last dropoff
    runs.joins(:run_distance).group("extract(month from date)").sum("revenue_miles + non_revenue_miles")
  end

end