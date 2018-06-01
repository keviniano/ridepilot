class AddManifestChangedToRuns < ActiveRecord::Migration[5.1]
  def change
    add_column :runs, :manifest_changed, :boolean
  end
end
