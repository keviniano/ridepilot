require 'rails_helper'

RSpec.describe GpsLocation, type: :model do
  
  describe "partition" do 

    it "creats new partition for new provider and month" do 
      new_provider = create(:provider)
      log_time = Date.today
      table_name = "gps_locations_view_#{new_provider.id}_#{log_time.strftime('%Y_%m')}";
      expect { create(:gps_location, provider: new_provider, log_time: log_time) }.to change { 
        ActiveRecord::Base.connection.table_exists?(table_name)
        }.from(false).to(true)

      expect(GpsLocation.count).to eq(1)
    end
  end

  describe "query by provider and month" do
    before do 
      @new_provider = create(:provider)
      @log_time_this_month = Date.new(2018,3,1)
      create(:gps_location, provider: @new_provider, log_time: @log_time_this_month - 1.month)
      create(:gps_location, provider: @new_provider, log_time: @log_time_this_month)
    end

    it "directlys queries child table" do 
      # last month
      expect(GpsLocation.from_partition(@new_provider.id, 2018, 2).count).to eq(1)
      # this month
      expect(GpsLocation.from_partition(@new_provider.id, 2018, 3).count).to eq(1)
    end 
  end
end
