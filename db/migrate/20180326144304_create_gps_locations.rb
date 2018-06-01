class CreateGpsLocations < ActiveRecord::Migration[5.1]
  def up
    create_table :gps_location_partitions do |t|
      t.integer :provider_id
      t.integer :year
      t.integer :month
      t.string :table_name
    end

    create_table :gps_locations do |t|
      t.float :lat
      t.float :lng
      t.float :bearing
      t.float :speed
      t.datetime :log_time
      t.integer :accuracy
      t.references :provider, foreign_key: true
      t.references :run, foreign_key: true
      t.integer :itinerary_id

      t.timestamps
    end

    add_index :gps_locations, [:provider_id, :log_time]

    Rake::Task["sql:create_gps_locations_partition"].invoke
  end

  def down
    GpsLocationPartition.destroy_all
    Rake::Task["sql:drop_gps_locations_partition"].invoke

    remove_index :gps_locations, [:provider_id, :log_time]
    drop_table :gps_locations
    drop_table :gps_location_partitions
  end
end
