class GpsLocation < ApplicationRecord
  self.table_name = "gps_locations_view"
  
  belongs_to :provider
  belongs_to :run

  def self.from_partition(provider_id, year, month)
    child_table_name = self.partition_name(provider_id, year, month)
    self.from(child_table_name).select('*')
  end

  def self.partition_name(provider_id, year, month)
    "#{self.table_name}_#{provider_id}_#{'%04d' % year}_#{'%02d' % month}"
  end
end
