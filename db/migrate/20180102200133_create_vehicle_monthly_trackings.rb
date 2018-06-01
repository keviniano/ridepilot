class CreateVehicleMonthlyTrackings < ActiveRecord::Migration[5.1]
  def change
    create_table :vehicle_monthly_trackings do |t|
      t.references :provider, index: true
      t.integer :year
      t.integer :month
      t.integer :max_available_count

      t.timestamps
    end
  end
end
