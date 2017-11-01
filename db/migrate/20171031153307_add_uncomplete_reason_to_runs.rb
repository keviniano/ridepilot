class AddUncompleteReasonToRuns < ActiveRecord::Migration
  def change
    add_column :runs, :uncomplete_reason, :text
  end
end
