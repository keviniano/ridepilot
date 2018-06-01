class TweakColumnsInGpsLocations < ActiveRecord::Migration[5.1]
  def change
    Rake::Task["sql:drop_gps_locations_partition"].invoke
    rename_column :gps_locations, :lat, :latitude
    rename_column :gps_locations, :lng, :longitude
    remove_column :gps_locations, :created_at
    remove_column :gps_locations, :updated_at

    Rake::Task["sql:create_gps_locations_partition"].invoke
  end
end
