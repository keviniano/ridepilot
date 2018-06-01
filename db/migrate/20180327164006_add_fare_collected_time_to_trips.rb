class AddFareCollectedTimeToTrips < ActiveRecord::Migration[5.1]
  def change
    add_column :trips, :fare_collected_time, :datetime
  end
end
