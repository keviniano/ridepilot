class AddFieldsToVehicleInspections < ActiveRecord::Migration[5.1]
  def change
    add_column :vehicle_inspections, :flagged, :boolean
    add_column :vehicle_inspections, :mechnical, :boolean
  end
end
