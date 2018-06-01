require 'rails_helper'

RSpec.describe GpsLocationPartition, type: :model do

  it "creats new partition reference when a new partition is created" do 
    new_provider = create(:provider)
    log_time = Date.today
    table_name = "gps_locations_view_#{new_provider.id}_#{log_time.strftime('%Y_%m')}";
    
    expect { create(:gps_location, provider: new_provider, log_time: log_time) }.to change { 
      GpsLocationPartition.count
      }.from(0).to(1)

    expect(GpsLocationPartition.first.table_name).to eq(table_name)
  end

  skip "drops partition when reference is destroyed" do 
    new_provider = create(:provider)
    log_time = Date.today
    table_name = "gps_locations_view_#{new_provider.id}_#{log_time.strftime('%Y_%m')}";
    create(:gps_location, provider: new_provider, log_time: log_time) 

    expect { GpsLocationPartition.first.destroy }.to change { 
      ActiveRecord::Base.connection.table_exists?(table_name)
      }.from(true).to(false)

  end
  
end
