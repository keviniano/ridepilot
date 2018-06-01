class CreateFares < ActiveRecord::Migration[5.1]
  def change
    create_table :fares do |t|
      t.integer :fare_type
      t.boolean :pre_trip
      t.boolean :fixed_fare

      t.timestamps
    end
  end
end
