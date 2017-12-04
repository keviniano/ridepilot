class OperatingHoursController < ApplicationController
  before_action :load_operatable

  respond_to :html, :js

  def new
    @date_flag = params[:date_flag]
    @available_times = current_provider.operating_hours.for_day_of_week(@date_flag).get_available_times(interval: (current_provider.driver_availability_interval_min || 30).minutes)
    @operating_hour = @operatable.operating_hours.new(day_of_week: @date_flag)
  end

  def add
    if @operatable
      if params[:is_all_day] == 'true'
        @is_all_day = true;
      elsif params[:is_unavailable] == 'true'
        @is_unavailable = true
      end

      @has_error = OperatingHoursProcessor.new(@operatable,{
        is_all_day: @is_all_day,
        is_unavailable: @is_unavailable,
        day_of_week: params[:date_flag],
        start_time: params[:start_time],
        end_time: params[:end_time]
        }).process!
    end

    if !@has_error && !@is_all_day && !@is_unavailable
      @time_ranges = []
      @operatable.operating_hours.regular.for_day_of_week(params[:date_flag]).pluck(:start_time, :end_time).each do |t|
        @time_ranges << [(t[0] - t[0].at_beginning_of_day) / 3600.0, (t[1] - t[1].at_beginning_of_day) / 3600.0]
      end
    end
  end

  def remove
    if @operatable
      @operatable.operating_hours.for_day_of_week(params[:date_flag]).destroy_all
    end
  end

  private

  def load_operatable
    @operatable = OperatingHour.new(operatable_id: params[:operatable_id], operatable_type: params[:operatable_type]).operatable
  end
end