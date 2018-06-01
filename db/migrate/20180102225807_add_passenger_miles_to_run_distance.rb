class AddPassengerMilesToRunDistance < ActiveRecord::Migration[5.1]
  def change
    add_column :run_distances, :passenger_miles, :float
  end
end
