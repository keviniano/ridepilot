class ChangeRepeatingTripEarlyPickupAllowed < ActiveRecord::Migration[5.1]
  def change
    remove_column :repeating_trips, :early_pickup_allowed
    add_column :repeating_trips, :early_pickup_allowed, :boolean
  end
end
