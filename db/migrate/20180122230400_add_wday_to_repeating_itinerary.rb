class AddWdayToRepeatingItinerary < ActiveRecord::Migration[5.1]
  def change
    add_column :repeating_itineraries, :wday, :integer
  end
end
