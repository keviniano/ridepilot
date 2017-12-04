class CreateVehicleCapacityConfigurations < ActiveRecord::Migration
  def change
    create_table :vehicle_capacity_configurations do |t|
      t.references :vehicle_type, index: true

      t.timestamps
    end
  end
end
