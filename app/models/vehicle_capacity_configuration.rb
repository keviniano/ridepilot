class VehicleCapacityConfiguration < ApplicationRecord
  belongs_to :vehicle_type
  has_many :vehicle_capacities, dependent: :destroy, foreign_key: :host_id

  accepts_nested_attributes_for :vehicle_capacities

  validate :must_have_capacity
  validate :unique_configuration_per_vehicle_type

  def capacity_in_array
    capacity_data = []

    vehicle_capacities.each do |vc|
      next unless vc.capacity.to_i > 0
      capacity_data << [vc.capacity_type_id, vc.capacity.to_i]
    end

    capacity_data
  end

  private

  def must_have_capacity
    if vehicle_capacities.any?
      has_capacity = false
      vehicle_capacities.each do |vc|
        if vc.capacity.to_i > 0
          has_capacity = true 
          break
        end
      end

      unless has_capacity
        errors.add(:base, "Must have at least capacity for one type")
      end
    end
  end

  def unique_configuration_per_vehicle_type
    if vehicle_type
      
      capacity_data = capacity_in_array
      
      has_duplicate = false
      vehicle_type.vehicle_capacity_configurations.each do |config|
        next if config == self

        config_capacity_data = config.capacity_in_array

        if capacity_data == config_capacity_data
          has_duplicate = true

          break
        end
      end

      if has_duplicate
        errors.add(:base, "This configuratin already exists")
      end
    end
  end
end
