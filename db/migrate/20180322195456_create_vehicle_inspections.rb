class CreateVehicleInspections < ActiveRecord::Migration[5.1]
  def change
    create_table :vehicle_inspections do |t|
      t.string :description
      t.datetime :deleted_at
      t.references :provider, foreign_key: true

      t.timestamps
    end
  end
end
