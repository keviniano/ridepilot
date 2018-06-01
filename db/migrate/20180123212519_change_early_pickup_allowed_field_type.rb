class ChangeEarlyPickupAllowedFieldType < ActiveRecord::Migration[5.1]
  def change
    remove_column :trips, :early_pickup_allowed
    add_column :trips, :early_pickup_allowed, :boolean
  end
end
