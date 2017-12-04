class PlannedLeavesController < ApplicationController
  before_action :load_leavable

  respond_to :html, :js

  def new
    @planned_leave = new_planned_leave
  end

  def create
    @planned_leave = new_planned_leave
    @planned_leave.assign_attributes(planned_leave_params)

    if @planned_leave.save
      unassign_unavailable_drivers

      respond_to do |format|
        format.html { redirect_to @planned_leave, notice: 'Planned leave was successfully created.' }
        format.js
      end
    else
      render :new
    end
  end

  def edit
    @planned_leave = PlannedLeave.find_by_id(params[:id])
  end

  def update
    @planned_leave = PlannedLeave.find_by_id(params[:id])
    @planned_leave.assign_attributes(planned_leave_params)
    
    if @planned_leave.save
      unassign_unavailable_drivers

      respond_to do |format|
        format.html { redirect_to @planned_leave, notice: 'Planned leave was successfully updated.' }
        format.js
      end
    else
      render :edit
    end
  end

  def destroy
    @planned_leave = PlannedLeave.find_by_id(params[:id])
    @planned_leave.destroy
    respond_to do |format|
      format.html { redirect_to :back, notice: 'Vehicle warranty was successfully destroyed.' }
      format.js
    end
  end

  private

  def new_planned_leave
    PlannedLeave.new(leavable_id: params[:leavable_id], leavable_type: params[:leavable_type])
  end

  def planned_leave_params
    params.require(:planned_leave).permit(:start_date, :end_date, :reason)
  end

  def load_leavable
    @leavable = new_planned_leave.leavable
  end

  def unassign_unavailable_drivers
    if @planned_leave.leavable_type == 'Driver' && @planned_leave.start_date <= (Date.today + current_provider.get_advance_day_scheduling.day)
      # unassign this driver from future runs within leave range
      Run.for_provider(current_provider_id)
        .for_date_range(@planned_leave.start_date, @planned_leave.end_date + 1.day)
        .where(driver_id: @planned_leave.leavable_id)
        .update_all(driver_id: nil)
    end
  end
end