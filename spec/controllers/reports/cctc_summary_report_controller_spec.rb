require "rails_helper"

RSpec.describe ReportsController do
  describe "cctc_summary_report" do
    before :each do
      @test_user = create(:role, level: 100).user
      @test_provider = @test_user.current_provider
    
      @test_funding_sources = {}
      @test_funding_sources[:oaa3b]        = create(:funding_source, :name => "OAA")
      @test_funding_sources[:trimet]       = create(:funding_source, :name => "TriMet Non-Medical")
      @test_funding_sources[:rc]           = create(:funding_source, :name => "Ride Connection")
      @test_funding_sources[:stf]          = create(:funding_source, :name => "STF")
      @test_funding_sources[:unreimbursed] = create(:funding_source, :name => "Unreimbursed")
    
      @test_start_date = DateTime.new(2013, 2, 1).in_time_zone
    
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in @test_user

      @cctc_custom_report = create(:custom_report, name: 'cctc_summary_report')
    end

    it "is successful" do
      get :cctc_summary_report, params: {id: @cctc_custom_report.id}
      expect(response).to be_success
    end

    it "assigns the proper instance variables" do
      get :cctc_summary_report, params: {query: {start_date: @test_start_date.to_date.to_s}, id: @cctc_custom_report.id}
      expect(assigns(:provider)).to eq(@test_provider)
      expect(assigns(:start_date)).to eq(@test_start_date.to_date)
      expect(assigns(:report)).not_to be_nil
    end

    describe "total_miles" do
      before do
        # In report range
        create(:trip, provider: @test_provider, mileage: 1, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date, cab: false)
        create(:trip, provider: @test_provider, mileage: 1, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date, cab: true)
        create(:trip, provider: @test_provider, mileage: 1, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date)
        
        # Outside report range
        create(:trip, provider: @test_provider, mileage: 1, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month, cab: false)
        create(:trip, provider: @test_provider, mileage: 1, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month, cab: true)
        create(:trip, provider: @test_provider, mileage: 1, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date - 1.month)

        get :cctc_summary_report, params: {query: {start_date: @test_start_date.to_date.to_s}, id: @cctc_custom_report.id}
      end
      
      # TODO This test is failing on master. Uncomment after upgrade. Fix if
      # time allows.
      it "reports the proper mileage" do
        pending('failed during rideconnection rails upgrade')
        assigns(:report)[:total_miles][:stf][:van_bus].should eq(1)
        assigns(:report)[:total_miles][:stf][:taxi].should eq(1)
        assigns(:report)[:total_miles][:rc].should eq(1)
      end
    end
    
    describe "rider_information" do
      before do
        # Existing customers (by virtue of having trips before current report date range)
        ec_1 = create(:customer, birth_date: @test_start_date - 59.years, ada_eligible: true)  # under 60, ADA eligible
        ec_2 = create(:customer, birth_date: @test_start_date - 59.years, ada_eligible: false) # under 60, ADA ineligible
        ec_3 = create(:customer, birth_date: @test_start_date - 61.years, ada_eligible: true)  # over 60, ADA eligible
        ec_4 = create(:customer, birth_date: @test_start_date - 61.years, ada_eligible: false) # over 60, ADA ineligible
        
        # New customers (by virtue of not having any trips before current report date range)
        nc_1 = create(:customer, birth_date: @test_start_date - 59.years, ada_eligible: true)  # under 60, ADA eligible
        nc_2 = create(:customer, birth_date: @test_start_date - 59.years, ada_eligible: false) # under 60, ADA ineligible
        nc_3 = create(:customer, birth_date: @test_start_date - 61.years, ada_eligible: true)  # over 60, ADA eligible
        nc_4 = create(:customer, birth_date: @test_start_date - 61.years, ada_eligible: false) # over 60, ADA ineligible
        
        # Rides for existing customers, in report range
        create(:trip, provider: @test_provider, customer: ec_1, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: ec_2, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: ec_3, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: ec_4, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)

        create(:trip, provider: @test_provider, customer: ec_1, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: ec_2, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: ec_3, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: ec_4, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date)

        # Rides for existing customers, in YTD range
        create(:trip, provider: @test_provider, customer: ec_1, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: ec_2, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: ec_3, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: ec_4, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month)

        create(:trip, provider: @test_provider, customer: ec_1, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: ec_2, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: ec_3, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: ec_4, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date - 1.month)

        # Rides for existing customers, outside report range
        create(:trip, provider: @test_provider, customer: ec_1, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.year)
        create(:trip, provider: @test_provider, customer: ec_2, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.year)
        create(:trip, provider: @test_provider, customer: ec_3, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.year)
        create(:trip, provider: @test_provider, customer: ec_4, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.year)

        create(:trip, provider: @test_provider, customer: ec_1, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date - 1.year)
        create(:trip, provider: @test_provider, customer: ec_2, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date - 1.year)
        create(:trip, provider: @test_provider, customer: ec_3, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date - 1.year)
        create(:trip, provider: @test_provider, customer: ec_4, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date - 1.year)

        # Rides for new customers, in report range
        create(:trip, provider: @test_provider, customer: nc_1, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: nc_2, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: nc_3, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: nc_4, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)

        create(:trip, provider: @test_provider, customer: nc_1, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: nc_2, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: nc_3, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: nc_4, funding_source: @test_funding_sources[:rc], pickup_time: @test_start_date)
        
        get :cctc_summary_report, params: {query: {start_date: @test_start_date.to_date.to_s}, id: @cctc_custom_report.id}
      end
      
      describe "riders_new_this_month" do
        it "reports the correct number of new riders" do
          expect(assigns(:report)[:rider_information][:riders_new_this_month][:over_60][:stf]).to eq(2)
          expect(assigns(:report)[:rider_information][:riders_new_this_month][:over_60][:rc]).to eq(2)

          expect(assigns(:report)[:rider_information][:riders_new_this_month][:under_60][:stf]).to eq(2)
          expect(assigns(:report)[:rider_information][:riders_new_this_month][:under_60][:rc]).to eq(2)

          expect(assigns(:report)[:rider_information][:riders_new_this_month][:ada_eligible][:over_60]).to eq(2)
          expect(assigns(:report)[:rider_information][:riders_new_this_month][:ada_eligible][:under_60]).to eq(2)
        end        
      end

      describe "riders_ytd" do
        it "reports the correct number of new riders ytd" do
          expect(assigns(:report)[:rider_information][:riders_ytd][:over_60][:stf]).to eq(4)
          expect(assigns(:report)[:rider_information][:riders_ytd][:over_60][:rc]).to eq(4)

          expect(assigns(:report)[:rider_information][:riders_ytd][:under_60][:stf]).to eq(4)
          expect(assigns(:report)[:rider_information][:riders_ytd][:under_60][:rc]).to eq(4)

          expect(assigns(:report)[:rider_information][:riders_ytd][:ada_eligible][:over_60]).to eq(2)
          expect(assigns(:report)[:rider_information][:riders_ytd][:ada_eligible][:under_60]).to eq(2)
        end        
      end
    end
    
    describe "driver_information" do
      before do
        # Driver -> Run -> Trip
        
        # Existing Drivers (by virtue of having given rides before current report date range)
        ed_1 = create(:driver, provider: @test_provider, paid: true )
        ed_2 = create(:driver, provider: @test_provider, paid: false)

        # New Drivers (by virtue of not having given any rides before current report date range)
        nd_1 = create(:driver, provider: @test_provider, paid: true)
        nd_2 = create(:driver, provider: @test_provider, paid: false)
        
        # Runs for existing drivers, in report range
        vehicle = create(:vehicle)
        r_1 = create(:run, name: 'run_1', provider: @test_provider, driver: ed_1, paid: true,  date: @test_start_date, actual_start_time: @test_start_date, actual_end_time: @test_start_date + 30.minutes, unpaid_driver_break_time: 5, vehicle: vehicle)
        r_2 = create(:run, name: 'run_2', provider: @test_provider, driver: ed_2, paid: false, date: @test_start_date, actual_start_time: @test_start_date, actual_end_time: @test_start_date + 30.minutes, unpaid_driver_break_time: 5, vehicle: vehicle)

        # Runs for existing drivers, outside report range
        r_3 = create(:run, name: 'run_3', provider: @test_provider, driver: ed_1, paid: true,  date: @test_start_date - 1.month, actual_start_time: @test_start_date - 1.month, actual_end_time: @test_start_date - 1.month + 30.minutes, unpaid_driver_break_time: 5, vehicle: vehicle)
        r_4 = create(:run, name: 'run_4', provider: @test_provider, driver: ed_2, paid: false, date: @test_start_date - 1.month, actual_start_time: @test_start_date - 1.month, actual_end_time: @test_start_date - 1.month + 30.minutes, unpaid_driver_break_time: 5, vehicle: vehicle)

        # Runs for new drivers, in report range
        r_5 = create(:run, name: 'run_5', provider: @test_provider, driver: nd_1, paid: true,  date: @test_start_date, actual_start_time: @test_start_date, actual_end_time: @test_start_date + 30.minutes, unpaid_driver_break_time: 5, vehicle: vehicle)
        r_6 = create(:run, name: 'run_6', provider: @test_provider, driver: nd_2, paid: false, date: @test_start_date, actual_start_time: @test_start_date, actual_end_time: @test_start_date + 30.minutes, unpaid_driver_break_time: 5, vehicle: vehicle)

        # Rides for existing drivers, in report range
        create(:trip, provider: @test_provider, run: r_1, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, run: r_2, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, run: r_1, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, run: r_2, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date)

        # Rides for existing drivers, outside report range
        create(:trip, provider: @test_provider, run: r_3, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, run: r_4, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, run: r_3, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, run: r_4, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date - 1.month)

        # Rides for new drivers, in report range
        create(:trip, provider: @test_provider, run: r_5, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, run: r_6, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, run: r_5, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, run: r_6, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date)

        get :cctc_summary_report, params: {query: {start_date: @test_start_date.to_date.to_s}, id: @cctc_custom_report.id}
      end
      
      describe "number_of_driver_hours" do
        it "reports the correct number of new driver hours" do
          expect(assigns(:report)[:driver_information][:number_of_driver_hours][:paid][:stf]).to eq(0.84)
          expect(assigns(:report)[:driver_information][:number_of_driver_hours][:paid][:rc]).to eq(0.84)

          expect(assigns(:report)[:driver_information][:number_of_driver_hours][:volunteer][:stf]).to eq(0.84)
          expect(assigns(:report)[:driver_information][:number_of_driver_hours][:volunteer][:rc]).to eq(0.84)
        end        
      end

      describe "number_of_active_drivers" do
        it "reports the correct number of active drivers" do
          expect(assigns(:report)[:driver_information][:number_of_active_drivers][:paid][:stf]).to eq(2)
          expect(assigns(:report)[:driver_information][:number_of_active_drivers][:paid][:rc]).to eq(2)

          expect(assigns(:report)[:driver_information][:number_of_active_drivers][:volunteer][:stf]).to eq(2)
          expect(assigns(:report)[:driver_information][:number_of_active_drivers][:volunteer][:rc]).to eq(2)
        end        
      end

      describe "drivers_new_this_month" do
        it "reports the correct number of new drivers" do
          expect(assigns(:report)[:driver_information][:drivers_new_this_month][:paid][:stf]).to eq(1)
          expect(assigns(:report)[:driver_information][:drivers_new_this_month][:paid][:rc]).to eq(1)

          expect(assigns(:report)[:driver_information][:drivers_new_this_month][:volunteer][:stf]).to eq(1)
          expect(assigns(:report)[:driver_information][:drivers_new_this_month][:volunteer][:rc]).to eq(1)
        end        
      end

      describe "escort_hours" do
        skip "Pending completion of ticket 1501"
      end

      describe "administrative_hours" do
        skip "Pending completion of ticket 1501"
      end
    end
    
    describe "rides_not_given" do
      before do
        # In report range
        td_result = create(:trip_result, code:"TD", name: "Turned down ")
        canc_result = create(:trip_result, code:"CANC", name: 'Cancelled')
        ns_result = create(:trip_result, code:'NS', name:"No-show")

        create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date, trip_result: td_result)
        create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date, trip_result: td_result)
        create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date, trip_result: canc_result)
        create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date, trip_result: canc_result)
        create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date, trip_result: ns_result)
        create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date, trip_result: ns_result)

        # Outside report range
        create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month, trip_result: td_result)
        create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date - 1.month, trip_result: td_result)
        create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month, trip_result: canc_result)
        create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date - 1.month, trip_result: canc_result)
        create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month, trip_result: ns_result)
        create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date - 1.month, trip_result: ns_result)

        get :cctc_summary_report, params: {query: {start_date: @test_start_date.to_date.to_s}, id: @cctc_custom_report.id}
      end
      
      describe "turndowns" do
        it "reports the correct number of turned-down trips" do
          expect(assigns(:report)[:rides_not_given][:turndowns][:stf]).to eq(1)
          expect(assigns(:report)[:rides_not_given][:turndowns][:rc]).to eq(1)
        end
      end

      describe "cancels" do
        it "reports the correct number of canceled trips" do
          expect(assigns(:report)[:rides_not_given][:cancels][:stf]).to eq(1)
          expect(assigns(:report)[:rides_not_given][:cancels][:rc]).to eq(1)
        end
      end

      describe "no_shows" do
        it "reports the correct number of no-show trips" do
          expect(assigns(:report)[:rides_not_given][:no_shows][:stf]).to eq(1)
          expect(assigns(:report)[:rides_not_given][:no_shows][:rc]).to eq(1)
        end
      end
    end
    
    describe "rider_donations" do
      before do
        # In report range
        trip_1 = create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date)
        trip_2 = create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)

        # Outside report range
        trip_3 = create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month)
        trip_4 = create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date - 1.month)

        # donations
        create(:donation, trip: trip_1, customer: trip_1.customer, date: trip_1.pickup_time, amount: 1.23)
        create(:donation, trip: trip_2, customer: trip_2.customer, date: trip_2.pickup_time, amount: 1.23)
        create(:donation, trip: trip_3, customer: trip_3.customer, date: trip_3.pickup_time, amount: 1.23)
        create(:donation, trip: trip_4, customer: trip_4.customer, date: trip_4.pickup_time, amount: 1.23)

        get :cctc_summary_report, params: {query: {start_date: @test_start_date.to_date.to_s}, id: @cctc_custom_report.id}
      end
      
      it "reports the correct amount of donations" do
        expect(assigns(:report)[:rider_donations][:stf]).to eq(1.23)
        expect(assigns(:report)[:rider_donations][:rc]).to eq(1.23)
      end
    end
    
    describe "trip_purposes" do
      before do
        # trip_purposes: {trips: [], total_rides: {}, reimbursements_due: {}}, # We will loop over and add these later
        @test_provider.oaa3b_per_ride_reimbursement_rate = 1.23
        @test_provider.ride_connection_per_ride_reimbursement_rate = 1.23
        @test_provider.trimet_per_ride_reimbursement_rate = 1.23
        @test_provider.stf_van_per_ride_reimbursement_rate = 1.23
        @test_provider.stf_taxi_per_ride_wheelchair_load_fee = 1.23
        @test_provider.stf_taxi_per_mile_wheelchair_reimbursement_rate = 1.23
        @test_provider.stf_taxi_per_ride_ambulatory_load_fee = 1.23
        @test_provider.stf_taxi_per_mile_ambulatory_reimbursement_rate = 1.23
        @test_provider.stf_taxi_per_ride_administrative_fee = 1.23
        @test_provider.save!

        wheelchair_service_level = create(:service_level, name: 'Wheelchair')
        ambulatory_service_level = create(:service_level, name: 'Ambulatory')
          
        @trip_purpose_names = [
          "Life-Sustaining Medical", 
          "Medical", 
          "Nutrition", 
          "Personal/Support Services", 
          "Recreation", 
          "School/Work", 
          "Shopping", 
          "Volunteer Work", 
          "Center"]
        @trip_purpose_count = @trip_purpose_names.size

        @trip_purpose_names.each do |trip_purpose_name|
          trip_purpose = create(:trip_purpose, name: trip_purpose_name)
          @test_funding_sources.keys.reject{|k| k == :stf}.each do |funding_source|
            # In report range, 
            create(:trip, provider: @test_provider, funding_source: @test_funding_sources[funding_source], pickup_time: @test_start_date, trip_purpose: trip_purpose )
            create(:trip, provider: @test_provider, funding_source: @test_funding_sources[funding_source], pickup_time: @test_start_date, trip_purpose: trip_purpose, direction: :return)
          
            # Outside report range
            create(:trip, provider: @test_provider, funding_source: @test_funding_sources[funding_source], pickup_time: @test_start_date - 1.month, trip_purpose: trip_purpose)
            create(:trip, provider: @test_provider, funding_source: @test_funding_sources[funding_source], pickup_time: @test_start_date - 1.month, trip_purpose: trip_purpose, direction: :return)
          end
          
          # STF taxi rides, in report range
          create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date, trip_purpose: trip_purpose, service_level: wheelchair_service_level, mileage: 1, cab: true)
          create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date, trip_purpose: trip_purpose, service_level: wheelchair_service_level, mileage: 1, cab: true, direction: :return)
          create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date, trip_purpose: trip_purpose, service_level: ambulatory_service_level, mileage: 1, cab: true)
          create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date, trip_purpose: trip_purpose, service_level: ambulatory_service_level, mileage: 1, cab: true, direction: :return)
          
          # STF taxi rides, outside report range
          create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month, trip_purpose: trip_purpose, service_level: wheelchair_service_level, mileage: 1, cab: true)
          create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month, trip_purpose: trip_purpose, service_level: wheelchair_service_level, mileage: 1, cab: true, direction: :return)
          create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month, trip_purpose: trip_purpose, service_level: ambulatory_service_level, mileage: 1, cab: true)
          create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month, trip_purpose: trip_purpose, service_level: ambulatory_service_level, mileage: 1, cab: true, direction: :return)
          
          # STF non-taxi rides, in report range
          create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date, trip_purpose: trip_purpose)
          create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date, trip_purpose: trip_purpose, direction: :return)
          
          # STF non-taxi rides, outside report range
          create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month, trip_purpose: trip_purpose)
          create(:trip, provider: @test_provider, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month, trip_purpose: trip_purpose, direction: :return)          
        end
        
        get :cctc_summary_report, params: {query: {start_date: @test_start_date.to_date.to_s}, id: @cctc_custom_report.id}
      end
      
      describe "trips" do
        it "reports the correct trip purpose data" do

          expect(assigns(:report)[:trip_purposes][:trips].collect{|t| t[:name]}.sort).to match(@trip_purpose_names.sort)
          
          assigns(:report)[:trip_purposes][:trips].each do |trip|
            @test_funding_sources.keys.reject{|k| k == :stf}.each do |funding_source|
              expect(trip[funding_source]).to eq(2)
            end

            # STF taxi rides
            expect(trip[:stf_taxi][:all][:count]).to eq(4)
            expect(trip[:stf_taxi][:all][:mileage]).to eq(4)
            
            expect(trip[:stf_taxi][:wheelchair][:count]).to eq(2)
            expect(trip[:stf_taxi][:wheelchair][:mileage]).to eq(2)
            
            expect(trip[:stf_taxi][:ambulatory][:count]).to eq(2)
            expect(trip[:stf_taxi][:ambulatory][:mileage]).to eq(2)
            
            # STF non-taxi rides
            expect(trip[:stf_van]).to eq(2)
            
            # Total rides
            expect(trip[:total_rides]).to eq(14)
          end
        end
      end

      describe "total_rides" do
        it "reports the correct number of total rides" do
          @test_funding_sources.keys.reject{|k| k == :stf}.each do |funding_source|
            expect(assigns(:report)[:trip_purposes][:total_rides][funding_source]).to eq(@trip_purpose_count * 2)
          end
          
          expect(assigns(:report)[:trip_purposes][:total_rides][:stf_taxi]).to eq(@trip_purpose_count * 4)
          expect(assigns(:report)[:trip_purposes][:total_rides][:stf_van]).to eq(@trip_purpose_count * 2)
        end
      end

      describe "reimbursements_due" do
        it "reports the correct reimbursement amounts due" do
          expect(assigns(:report)[:trip_purposes][:reimbursements_due][:oaa3b]).to eq(1.23 * @trip_purpose_count * 2)
          expect(assigns(:report)[:trip_purposes][:reimbursements_due][:rc]).to eq(1.23 * @trip_purpose_count * 2)
          expect(assigns(:report)[:trip_purposes][:reimbursements_due][:trimet]).to eq(1.23 * @trip_purpose_count * 2)
          expect(assigns(:report)[:trip_purposes][:reimbursements_due][:stf_van]).to eq(1.23 * @trip_purpose_count * 2)

          expect(assigns(:report)[:trip_purposes][:reimbursements_due][:stf_taxi]).to eq(
            (@trip_purpose_count * 2 * 1.23) +
            (@trip_purpose_count * 2 * 1.23) +
            (@trip_purpose_count * 2 * 1.23) +
            (@trip_purpose_count * 2 * 1.23) +
            (@trip_purpose_count * 4 * 1.23)
          )
        end
      end
    end
    
    describe "new_rider_ethinic_heritage" do
      before do
        e_1 = create(:ethnicity, :name => "Ethnicity 1")
        e_2 = create(:ethnicity, :name => "Ethnicity 2")
        e_3 = create(:ethnicity, :name => "Other")
        
        c_1 = create(:customer, ethnicity: e_1.name)
        c_2 = create(:customer, ethnicity: e_2.name)
        c_3 = create(:customer, ethnicity: e_3.name)
        c_4 = create(:customer, ethnicity: "Something Else")

        # In report range
        create(:trip, provider: @test_provider, customer: c_1, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: c_1, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: c_2, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: c_2, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: c_3, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: c_3, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: c_4, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date)
        create(:trip, provider: @test_provider, customer: c_4, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date)
        
        # Outside report range
        create(:trip, provider: @test_provider, customer: c_1, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: c_1, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: c_2, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: c_2, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: c_3, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: c_3, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: c_4, funding_source: @test_funding_sources[:stf], pickup_time: @test_start_date - 1.month)
        create(:trip, provider: @test_provider, customer: c_4, funding_source: @test_funding_sources[:rc],  pickup_time: @test_start_date - 1.month)

        get :cctc_summary_report, params: {query: {start_date: @test_start_date.to_date.to_s}, id: @cctc_custom_report.id}
      end
      
      describe "ethnicities" do
        it "reports the correct ethnicity information" do
          expect(assigns(:report)[:new_rider_ethinic_heritage][:ethnicities].collect{|e| e[:name]}).to match(Ethnicity.by_provider(@test_provider).collect(&:name))
                    
          Ethnicity.by_provider(@test_provider).reject{|e| e.name == "Other"}.each do |ethnicity|
            e = assigns(:report)[:new_rider_ethinic_heritage][:ethnicities].find{|e| e[:name] == ethnicity.name}
            expect(e).not_to be_nil
            expect(e[:trips][:rc]).to eq(1)
            expect(e[:trips][:stf]).to eq(1)
          end
          
          e = assigns(:report)[:new_rider_ethinic_heritage][:ethnicities].find{|e| e[:name] == "Other"}
          expect(e).not_to be_nil
          expect(e[:trips][:rc]).to eq(2)
          expect(e[:trips][:stf]).to eq(2)
        end
      end
    end
  end
end
