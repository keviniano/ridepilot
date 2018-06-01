class AddFareReferences < ActiveRecord::Migration[5.1]
  def change
    add_reference :providers, :fare, index: true
    add_reference :trips, :fare, index: true
  end
end
