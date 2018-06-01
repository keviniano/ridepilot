class AddFareAmountToTrip < ActiveRecord::Migration[5.1]
  def change
    add_column :trips, :fare_amount, :float
  end
end
