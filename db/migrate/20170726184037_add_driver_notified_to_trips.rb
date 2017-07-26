class AddDriverNotifiedToTrips < ActiveRecord::Migration
  def change
    add_column :trips, :driver_notified, :boolean
  end
end
