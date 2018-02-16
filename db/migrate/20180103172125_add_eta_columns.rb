class AddEtaColumns < ActiveRecord::Migration
  def change
    add_column :providers,  "passenger_load_min", :integer
    add_column :providers,  "passenger_unload_min", :integer
    add_column :providers,  "very_early_arrival_threshold_min", :integer
    add_column :providers,  "early_arrival_threshold_min", :integer
    add_column :providers,  "late_arrival_threshold_min", :integer
    add_column :providers,  "very_late_arrival_threshold_min", :integer

    add_column :customers,  "passenger_load_min", :integer
    add_column :customers,  "passenger_unload_min", :integer

    add_column :trips,  "passenger_load_min", :integer
    add_column :trips,  "passenger_unload_min", :integer
    add_column :trips,  "early_pickup_allowed", :integer

    add_column :repeating_trips,  "passenger_load_min", :integer
    add_column :repeating_trips,  "passenger_unload_min", :integer
    add_column :repeating_trips,  "early_pickup_allowed", :integer
  end
end
