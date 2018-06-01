class CreateItineraries < ActiveRecord::Migration[5.1]
  def change
    create_table :itineraries do |t|
      t.datetime :time
      t.datetime :eta
      t.integer :travel_time
      t.references :address, index: true
      t.references :run, index: true
      t.references :trip, index: true
      t.integer :leg_flag

      t.timestamps
    end
  end
end
