class AddLinkingTripIdToRepeatingTrips < ActiveRecord::Migration
  def change
    add_column :repeating_trips, :linking_trip_id, :integer
    add_index :repeating_trips, :linking_trip_id
  end
end
