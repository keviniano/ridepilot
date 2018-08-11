class VehicleInspectionsController < ApplicationController
  
  respond_to :html, :js

  def mark_flagged
    if params[:vehicle_inspection]
      insp = VehicleInspection.find_by_id(params[:id])
      if insp
        insp.flagged = params[:vehicle_inspection][:flagged]
        insp.save(validate: false)
      end
    end

    render json: {}
  end

  def mark_mechnical
    if params[:vehicle_inspection]
      insp = VehicleInspection.find_by_id(params[:id])
      if insp
        insp.mechnical = params[:vehicle_inspection][:mechnical]
        insp.save(validate: false)
      end
    end

    render json: {}
  end
end