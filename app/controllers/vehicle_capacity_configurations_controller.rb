class VehicleCapacityConfigurationsController < ApplicationController
  load_and_authorize_resource :vehicle_type
  load_and_authorize_resource :vehicle_capacity_configuration, through: :vehicle_type, except: [:create]
  respond_to :html, :js


  def new
  end

  def create
    @vehicle_capacity_configuration = VehicleCapacityConfiguration.new
    @vehicle_capacity_configuration.attributes = capacity_params
    @vehicle_capacity_configuration.vehicle_type = @vehicle_type
    if @vehicle_capacity_configuration.save
      @capacity_types = CapacityType.by_provider(current_provider).order(:name)
      respond_to do |format|
        format.js
      end
    else
      render :new
    end
  end

  def destroy
    @vehicle_capacity_configuration.destroy
    respond_to do |format|
      format.js
    end
  end

  def list 
    @vehicle_capacity_configurations = @vehicle_type.vehicle_capacity_configurations
  end

  private 

  def capacity_params
    params.require(:vehicle_capacity_configuration).permit(
      :vehicle_type_id,
      :vehicle_capacities_attributes => [
        :capacity,
        :capacity_type_id
      ]
    )
  end
  
end
