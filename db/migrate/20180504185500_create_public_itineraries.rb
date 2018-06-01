class CreatePublicItineraries < ActiveRecord::Migration[5.1]
  def change
    create_table :public_itineraries do |t|
      t.references :run
      t.references :itinerary
      t.datetime :eta
      t.integer :sequence

      t.timestamps
    end
  end
end
