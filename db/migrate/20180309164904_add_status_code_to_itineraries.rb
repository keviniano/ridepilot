class AddStatusCodeToItineraries < ActiveRecord::Migration[5.1]
  def change
    add_column :itineraries, :status_code, :integer
  end
end
