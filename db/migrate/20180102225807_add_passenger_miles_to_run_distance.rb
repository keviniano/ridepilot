class AddPassengerMilesToRunDistance < ActiveRecord::Migration
  def change
    add_column :run_distances, :passenger_miles, :float
  end
end
