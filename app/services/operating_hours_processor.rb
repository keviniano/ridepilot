class OperatingHoursProcessor
  attr_reader :operatable, :params

  def initialize(operatable, params = {})
    @operatable = operatable
    @params = params
  end

  def process!
    has_errors = false
    if @params[:is_all_day]
      @operatable.operating_hours.for_day_of_week(@params[:day_of_week]).destroy_all
      all_day_hour = @operatable.operating_hours.new(day_of_week: @params[:day_of_week])
      all_day_hour.make_all_day
      all_day_hour.save
    elsif @params[:is_unavailable]
      @operatable.operating_hours.for_day_of_week(@params[:day_of_week]).destroy_all
      unavailable_hour = @operatable.operating_hours.new(day_of_week: @params[:day_of_week])
      unavailable_hour.make_unavailable
      unavailable_hour.save
    else
      begin
        @operatable.operating_hours.for_day_of_week(@params[:day_of_week]).all_day.destroy_all
        @operatable.operating_hours.for_day_of_week(@params[:day_of_week]).unavailable.destroy_all
        regular_hour = @operatable.operating_hours.new(day_of_week: @params[:day_of_week])
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