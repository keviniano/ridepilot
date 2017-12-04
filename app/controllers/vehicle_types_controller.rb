class VehicleTypesController < ApplicationController
  load_and_authorize_resource except: [:create]

  respond_to :html, :js

  def index
    @vehicle_types = VehicleType.for_provider(current_provider_id)
  end

  def show
    @capacity_types = CapacityType.by_provider(current_provider).order(:name)
  end

  def new
  end

  def create
    @vehicle_type = VehicleType.new(vehicle_type_params)
    @vehicle_type.provider_id = current_provider_id
    if @vehicle_type.save
      respond_to do |format|
        format.html { redirect_to vehicle_types_path, notice: 'A new type was successfully created.' }
        format.js
      end
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @vehicle_type.update(vehicle_type_params)
      respond_to do |format|
        format.html { redirect_to @vehicle_type, notice: 'Vehicle type was successfully updated.' }
        format.js
      end
    else
      render :edit
    end
  end

  def destroy
    @vehicle_type.destroy
    respond_to do |format|
      format.html { redirect_to vehicle_types_path, notice: 'Vehicle type was successfully destroyed.' }
      format.js
    end
  end

  private

  def vehicle_type_params
    params.require(:vehicle_type).permit(:name)
  end
end