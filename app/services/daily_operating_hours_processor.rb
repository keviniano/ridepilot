class DailyOperatingHoursProcessor
  attr_reader :operatable, :params

  def initialize(operatable, params = {})
    @operatable = operatable
    @params = params
  end

  def process!
    has_errors = false
    if @params[:is_all_day]
      @operatable.daily_operating_hours.for_date(@params[:date]).destroy_all
      all_day_hour = @operatable.daily_operating_hours.new(date: @params[:date])
      all_day_hour.make_all_day
      all_day_hour.save
    elsif @params[:is_unavailable]
      @operatable.daily_operating_hours.for_date(@params[:date]).destroy_all
      unavailable_hour = @operatable.daily_operating_hours.new(date: @params[:date])
      unavailable_hour.make_unavailable
      unavailable_hour.save
    else
      begin
        @operatable.daily_operating_hours.for_date(@params[:date]).all_day.destroy_all
        @operatable.daily_operating_hours.for_date(@params[:date]).unavailable.destroy_all
        regular_hour = @operatable.daily_operating_hours.new(date: @params[:date])
        regular_hour.start_time = @params[:start_time]
        regular_hour.end_time = @params[:end_time]
        regular_hour.save
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug e.message
        has_errors = true
      end
    end

    has_errors
  end

end