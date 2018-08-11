class AddRunIdToMessage < ActiveRecord::Migration[5.1]
  def change
    add_reference :messages, :run, foreign_key: true
  end
end
