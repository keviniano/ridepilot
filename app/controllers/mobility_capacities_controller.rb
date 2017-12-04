class MobilityCapacitiesController < ApplicationController
  load_and_authorize_resource :mobility_capacity

  def index
    @capacity_types = CapacityType.by_provider(current_provider).order(:name)
    @mobility_types = Mobility.by_provider(current_provider).order(:name)
    @mobility_capacity_mappings = @mobility_capacities.group_by{|c|[c.host_id, c.capacity_type_id]}
  end

  def batch_edit
    @capacity_types = CapacityType.by_provider(current_provider).order(:name)
    @mobility_types = Mobility.by_provider(current_provider).order(:name)
    @mobility_capacity_mappings = @mobility_capacities.group_by{|c|[c.host_id, c.capacity_type_id]}
  end

  def batch_update
    capacities = params[:capacities]
    MobilityCapacity.delete_all
    
    capacities.each do |mobility_id, data|
      data.each do |capacity_type_id, capacity|
        new_item = MobilityCapacity.new(host_id: mobility_id, capacity_type_id: capacity_type_id, capacity: capacity.to_i)
        new_item.save
      end
    end
  end

  private 
  
end
