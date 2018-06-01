class AddManifestPublishedAtToRuns < ActiveRecord::Migration[5.1]
  def change
    add_column :runs, :manifest_published_at, :datetime
  end
end
