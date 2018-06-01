class CreateRunVehicleInspections < ActiveRecord::Migration[5.1]
  def change
    create_table :run_vehicle_inspections do |t|
      t.references :run, foreign_key: true
      t.references :vehicle_inspection, foreign_key: true
      t.boolean :checked

      t.timestamps
    end
  end
end
