class AddDeletedAtToItineraries < ActiveRecord::Migration[5.1]
  def change
    add_column :itineraries, :deleted_at, :datetime
  end
end
