class CreateRepeatingItineraries < ActiveRecord::Migration
  def change
    create_table :repeating_itineraries do |t|
      t.datetime :time
      t.datetime :eta
      t.integer :travel_time
      t.references :address, index: true
      t.references :repeating_run, index: true
      t.references :repeating_trip, index: true
      t.integer :leg_flag

      t.timestamps
    end
  end
end
