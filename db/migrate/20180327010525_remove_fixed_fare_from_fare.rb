class RemoveFixedFareFromFare < ActiveRecord::Migration[5.1]
  def change
    remove_column :fares, :fixed_fare
  end
end
