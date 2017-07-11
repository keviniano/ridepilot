class TripsController < ApplicationController
  load_and_authorize_resource :except=>[:show]

  def index
    Date.beginning_of_week= :sunday

    # by default, select all trip results
    unless session[:trips_trip_result_id].present?
      session[:trips_trip_result_id] = [TripResult::UNSCHEDULED_ID, TripResult::SHOW_ALL_ID] + TripResult.pluck(:id).uniq
    end
    @trips = Trip.for_provider(current_provider_id).includes(:customer, :pickup_address, {:run => [:driver, :vehicle]}).distinct
    .references(:customer, :pickup_address, {:run => [:driver, :vehicle]}).order(:pickup_time)
    filter_trips

    @vehicles        = Vehicle.where(:provider_id => current_provider_id)
    if current_provider.try(:cab_enabled?)
      @vehicles = add_cab(@vehicles)
    end
    @drivers         = Driver.for_provider current_provider_id
    @start_pickup_date = Time.zone.at(session[:trips_start].to_i).to_date
    @end_pickup_date = Time.zone.at(session[:trips_end].to_i).to_date
    @days_of_week = trip_sessions[:days_of_week].blank? ? [0,1,2,3,4,5,6] : trip_sessions[:days_of_week].split(',').map(&:to_i)
    if can? :edit, Trip
      @trip_results = TripResult.by_provider(current_provider).order(:name).pluck(:name, :id)
    end

    if @start_pickup_date > @end_pickup_date
      flash.now[:alert] = TranslationEngine.translate_text(:from_date_cannot_later_than_to_date)
    else
      flash.now[:alert] = nil
    end

    respond_to do |format|
      format.html
      format.xml  { render :xml => @trips }
      format.json { render :json => @trips }
    end
  end

  # list trips for a specific customer within given date range
  def customer_trip_summary
    @customer = Customer.find_by_id params[:customer_id]
    @trips = Trip.where(customer_id: params[:customer_id])

    if params[:past_trips].present?
      @trips = @trips.order(pickup_time: :desc).prior_to(DateTime.now).limit(params[:past_trips])
    elsif params[:future_trips].present?
      @trips = @trips.order(pickup_time: :asc).after(DateTime.now).limit(params[:future_trips])
    else
      unless params[:start_date].blank? && params[:end_date].blank?
        utility = Utility.new
        if !params[:start_date].blank?
          t_start = utility.parse_date params[:start_date]
          @trips = @trips.where("pickup_time >= '#{t_start.beginning_of_day.utc.strftime "%Y-%m-%d %H:%M:%S"}'")
        end

        if !params[:end_date].blank?
          t_end = utility.parse_date params[:end_date]
          @trips = @trips.where("pickup_time <= '#{t_end.end_of_day.utc.strftime "%Y-%m-%d %H:%M:%S"}'")
        end
        @trips = @trips.order(pickup_time: :asc)
      else
        # last 10 trips by default
        @trips = @trips.order(pickup_time: :desc).prior_to(DateTime.now).limit(10)
      end
    end

    respond_to do |format|
      format.js
      format.json { render :json => @trips }
    end
  end

  def trips_requiring_callback
    #The trip coordinator has made decisions on whether to confirm or
    #turn down trips.  Now they want to call back the customer to tell
    #them what's happened.  This is a list of all customers who have
    #not been marked as informed, ordered by when they were last
    #called.

    @trips = Trip.accessible_by(current_ability).for_provider(current_provider_id).where(
      "customer_informed = false AND pickup_time >= ?", Date.today.in_time_zone.utc).order("called_back_at")

    respond_to do |format|
      format.html
      format.xml  { render :xml => @trips }
    end
  end

  def unscheduled
    #The trip coordinatior wants to confirm or turn down individual
    #trips.  This is a list of all trips that haven't been decided
    #on yet.

    @trips = Trip.accessible_by(current_ability).for_provider(current_provider_id).where(
      ["trip_result_id is NULL and pickup_time >= ? ", Date.today]).order("pickup_time")
  end

  def reconcile_cab
    #the cab company has sent a log of all trips in the past [time period]
    #we want to mark some trips as no-shows.  This will be a paginated
    #list of trips
    @trips = Trip.accessible_by(current_ability).for_provider(current_provider_id).includes(:trip_result).references(:trip_result).where(
      "cab = true and (trip_results.code = 'COMP' or trip_results.code = 'NS')").reorder("pickup_time desc").paginate :page=>params[:page], :per_page=>50
  end

  def no_show
    @trip = Trip.find(params[:trip_id])
    if can? :edit, @trip
      @trip.trip_result = TripResult.find_by(code: 'NS')
      @trip.save
    end
    redirect_to :action=>:reconcile_cab, :page=>params[:page]
  end

  def send_to_cab
    @trip = Trip.find(params[:trip_id])
    if can? :edit, @trip
      @trip.cab = true
      @trip.cab_notified = false
      @trip.trip_result = TripResult.find_by(code: 'COMP')
      @trip.save
    end
    redirect_to :action=>:reconcile_cab, :page=>params[:page]
  end

  def reached
    #mark the user as having been informed that their trip has been
    #approved or turned down
    @trip = Trip.find(params[:trip_id])
    if can? :edit, @trip
      @trip.called_back_at = Time.current
      @trip.called_back_by = current_user
      @trip.customer_informed = true
      @trip.save
    end
    redirect_to :action=>:trips_requiring_callback
  end

  def confirm
    @trip = Trip.find(params[:trip_id])
    if can? :edit, @trip
      @trip.trip_result = TripResult.find_by(code: 'COMP')
      @trip.save
    end
    redirect_to :action=>:unscheduled
  end

  def turndown
    @trip = Trip.find(params[:trip_id])
    if can? :edit, @trip
      @trip.trip_result = TripResult.find_by(code: 'TD')
      @trip.save
    end
    redirect_to :action=>:unscheduled
  end

  def callback
    @trip = Trip.find(params[:trip_id])
    @prev_customer_informed = @trip.customer_informed ? true: false

    if can? :edit, @trip
      @trip.customer_informed = params[:trip][:customer_informed]
      if !@trip.save
        @message = @trip.errors.full_messages.join(';')
      end
    else
      @message = TranslationEngine.translate_text(:operation_not_authorized)
    end

    respond_to do |format|
      format.js
    end
  end

  def change_result
    @trip = Trip.find(params[:trip_id])
    @prev_trip_result_id = @trip.trip_result_id

    if can? :edit, @trip
      if !@trip.update_attributes(change_result_params)
        @message = @trip.errors.full_messages.join(';')
      else
        TrackerActionLog.cancel_or_turn_down_trip(@trip, current_user) if @trip.is_cancelled_or_turned_down?

        @trip_result_filters = trip_sessions[:trip_result_id]
        if @trip.scheduled? && @trip.is_cancelled_or_turned_down?
          if @trip.run.present?
            @trip.run = nil
            @trip.save
          elsif @trip.cab
            @trip.cab = false
            @trip.save
          end
          @clear_trip_status = true
        end
      end
    else
      @message = TranslationEngine.translate_text(:operation_not_authorized)
    end

    respond_to do |format|
      format.js
    end
  end

  def new
    @trip = Trip.new(:provider_id => current_provider_id)

    if params[:run_id] && run = Run.find_by_id(params[:run_id])
      d = run.date
      t = run.scheduled_start_time || (d.at_midnight + 12.hours)
      @trip.run_id = run.id
      @trip.pickup_time = Time.zone.local(d.year, d.month, d.day, t.hour, t.min, 0)
      @trip.appointment_time = @trip.pickup_time + (current_provider.min_trip_time_gap_in_mins).minutes
    end

    if params[:customer_id] && customer = Customer.find_by_id(params[:customer_id])
      @trip.customer_id = customer.id
      @trip.pickup_address_id = customer.address_id if customer.address.try(:the_geom).present?
      @trip.mobility_id = customer.mobility_id
      @trip.funding_source_id = customer.default_funding_source_id
      @trip.service_level = customer.service_level
    end

    prep_view

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @trip }
      format.js   { @remote = true; render :json => {:form => render_to_string(:partial => 'form') }, :content_type => "text/json" }
    end
  end

  def edit
    prep_view

    respond_to do |format|
      format.html
      format.js  { @remote = true; render :json => {:form => render_to_string(:partial => 'form')}, :content_type => "text/json" }
    end
  end

  def clone
    @trip = @trip.clone_for_future!
    prep_view

    respond_to do |format|
      format.html { render action: :new }
      format.xml  { render :xml => @trip }
      format.js   { @remote = true; render :json => {:form => render_to_string(:partial => 'form') }, :content_type => "text/json" }
    end
  end

  def return
    if params[:trip].present?
      @trip = @trip.clone_for_return!(params[:trip][:pickup_time], params[:trip][:appointment_time])
    else
      @trip = @trip.clone_for_return!
    end

    @outbound_trip_id = params[:trip_id]
    prep_view

    respond_to do |format|
      format.html { render action: :new }
      format.xml  { render :xml => @trip }
      format.js   { @remote = true; render :json => {:form => render_to_string(:partial => 'form') }, :content_type => "text/json" }
    end
  end

  def show
    @trip = Trip.find(params[:id])
    prep_view

    authorize! :show, @trip unless @trip.customer && @trip.customer.authorized_for_provider(current_provider.id)

    respond_to do |format|
      format.html
      format.js  { @remote = true; render :json => {:form => render_to_string(:partial => 'form')}, :content_type => "text/json" }
      format.pdf do
        render pdf: "#{@trip.id}", footer: { right: '[page] of [topage]' }   # Excluding ".pdf" extension.
      end
    end
  end

  def create
    params[:trip][:provider_id] = current_provider_id
    handle_trip_params params[:trip]
    @trip = Trip.new(trip_params)
    process_google_address
    authorize! :manage, @trip

    if @trip.is_return? && params[:trip][:outbound_trip_id].present?
      @trip.outbound_trip = Trip.find_by_id(params[:trip][:outbound_trip_id])
    end

    respond_to do |format|
      if @trip.is_all_valid?(current_provider_id) && @trip.save
        @trip.update_donation current_user, params[:customer_donation].to_f if params[:customer_donation].present?
        TripDistanceCalculationWorker.perform_async(@trip.id) #sidekiq needs to run
        @ask_for_return_trip = true if @trip.is_outbound?
        format.html {
          if @ask_for_return_trip
            TrackerActionLog.create_trip(@trip, current_user)
            render action: :show
          else
            if @trip.is_return?
              TrackerActionLog.create_return_trip(@trip, current_user)
            end

            if params[:run_id].present?
              redirect_to(edit_run_path(@trip.run), :notice => 'Trip was successfully created.')
            else
              redirect_to(@trip, :notice => 'Trip was successfully created.')
            end
          end
        }
      else
        prep_view
        format.html { render :action => "new" }
      end
    end

  end

  # Check if trip is potentially double booked. Returns an array of possible double booked trips
  def check_double_booked
    params = check_double_booked_params
    unless params[:customer_id].blank? || params[:date].blank?
      @customer = Customer.find(params[:customer_id])
      double_booked_trips = @customer.trips.for_date(Date.parse(params[:date]))
        .where.not(id: params[:id]).order(:pickup_time, :appointment_time)
      double_booked_trips_json = double_booked_trips.map do |trip|
        {
          id: trip.id,
          pickup_time: trip.pickup_time.try(:to_s, :time_only),
          pickup_address: trip.pickup_address.try(:address_text),
          appointment_time: trip.appointment_time.try(:to_s, :time_only),
          dropoff_address: trip.dropoff_address.try(:address_text)
        }
      end
    else
      double_booked_trips_json = []
    end 
      
    respond_to do |format|
      format.js {
        render json: { trips: double_booked_trips_json }
      }
    end
  end

  def update
    if params[:trip][:customer_id] && customer = Customer.find_by_id(params[:trip][:customer_id])
      authorize! :read, customer
    else
      params[:trip][:customer_id] = @trip.customer_id
    end
    handle_trip_params params[:trip]
    process_google_address
    authorize! :manage, @trip

    @trip.assign_attributes(trip_params)
    is_address_changed = @trip.pickup_address_id_changed? || @trip.dropoff_address_id_changed?
    is_trip_result_changed = @trip.trip_result_id_changed?
    is_run_disrupted = @trip.run_disrupted_by_trip_changes?
    respond_to do |format|
      if @trip.is_all_valid?(current_provider_id) && @trip.save
        @trip.unschedule_trip if is_run_disrupted
        @trip.update_donation current_user, params[:customer_donation].to_f if params[:customer_donation].present?
        TripDistanceCalculationWorker.perform_async(@trip.id) if is_address_changed
        TrackerActionLog.cancel_or_turn_down_trip(@trip, current_user) if is_trip_result_changed && @trip.is_cancelled_or_turned_down? 

        format.html { redirect_to(@trip, :notice => 'Trip was successfully updated.')  }
        format.js {
          render :json => {:status => "success"}, :content_type => "text/json"
        }
      else
        prep_view
        format.html { render :action => "edit"  }
        format.js   { @remote = true; render :json => {:status => "error", :form => render_to_string(:partial => 'form') }, :content_type => "text/json" }
      end
    end
  end

  def destroy
    @trip = Trip.find(params[:id])
    @trip.destroy

    respond_to do |format|
      format.html { redirect_to(trips_url) }
      format.xml  { head :ok }
      format.js   { render :json => {:status => "success"}, :content_type => "text/json" }
    end
  end

  private

  def trip_params
    params.require(:trip).permit(
      :date, # virtual attribute used in setting pickup and appointment times
      :direction,
      :linking_trip_id,
      :appointment_time,
      :attendant_count,
      :customer_id,
      :customer_informed,
      :driver_id,
      :dropoff_address_id,
      :funding_source_id,
      :group_size,
      :guest_count,
      :medicaid_eligible,
      :mileage,
      :mobility_id,
      :notes,
      :pickup_address_id,
      :pickup_time,
      :provider_id, # We normally wouldn't accept this and would set it manually on the instance, but in this controller we're setting it in the params dynamically
      :run_id,
      :cab,
      :service_level_id,
      :trip_purpose_id,
      :trip_result_id,
      :result_reason,
      :vehicle_id,
      :mobility_device_accommodations,
      :number_of_senior_passengers_served,
      :number_of_disabled_passengers_served,
      :number_of_low_income_passengers_served,
      customer_attributes: [:id]
    )
  end

  def prep_view
    @customer           = @trip.customer
    @mobilities         = Mobility.by_provider(current_provider).order(:name)
    @funding_sources    = FundingSource.by_provider(current_provider)
    @trip_results       = TripResult.by_provider(current_provider).order(:name).pluck(:name, :id)
    @trip_purposes      = TripPurpose.by_provider(current_provider).order(:name)
    @drivers            = Driver.active.for_provider @trip.provider_id
    @trips              = [] if @trips.nil?
    @vehicles           = Vehicle.active.for_provider(@trip.provider_id)
    @vehicles           = add_cab(@vehicles) if current_provider.try(:cab_enabled?)
    @repeating_vehicles = @vehicles
    @service_levels     = ServiceLevel.by_provider(current_provider).order(:name).pluck(:name, :id)

    @trip.run_id = -1 if @trip.cab

    #cab_run = Run.new :cab => true
    #cab_run.id = -1
    #@runs = Run.for_provider(@trip.provider_id).incomplete_on(@trip.pickup_time.try(:to_date)) << cab_run
  end

  # Strong params for changing trip result and result_reason
  def change_result_params
    params.require(:trip).permit(:trip_result_id, :result_reason)
  end

  def handle_trip_params(trip_params)
    if trip_params[:run_id] == '-1'
      #cab trip
      trip_params[:run_id] = nil
      trip_params[:cab] = true
    else
      trip_params[:cab] = false
    end

    if trip_params[:customer_informed] and not @trip.customer_informed
      trip_params[:called_back_by] = current_user
      trip_params[:called_back_at] = DateTime.current.to_s
    end

  end

  def filter_trips
    filters_hash = params[:trip_filters] || {}

    update_sessions(filters_hash)

    trip_filter = TripFilter.new(@trips, trip_sessions)
    @trips = trip_filter.filter!
    # need to re-update start&end pickup filters
    # as default values are used if they were not presented initially
    update_sessions({
      start: trip_filter.filters[:start],
      end: trip_filter.filters[:end],
      days_of_week: trip_filter.filters[:days_of_week]
      })
  end

  def update_sessions(params = {})
    params.each do |key, val|
      session["trips_#{key}"] = val if !val.nil?
    end
  end

  def trip_sessions
    {
      start: session[:trips_start],
      end: session[:trips_end],
      customer_id: session[:trips_customer_id],
      trip_result_id: session[:trips_trip_result_id],
      status_id: session[:trips_status_id],
      days_of_week: session[:trips_days_of_week]
    }
  end
  
  def check_double_booked_params
    params.require(:trip).permit(:id, :customer_id, :date)
  end

  def add_cab(vehicles)
    cab_vehicle = Vehicle.new :name => "Cab"
    cab_vehicle.id = -1
    [cab_vehicle] + vehicles
  end

  def process_google_address
    if params[:trip][:pickup_address_id].blank? && !params[:trip_pickup_google_address].blank?
      addr_params = JSON(params[:trip_pickup_google_address])
      new_temp_addr = TempAddress.new(addr_params.select{|x| TempAddress.allowable_params.include?(x)})
      new_temp_addr.the_geom = RGeo::Geographic.spherical_factory(srid: 4326).point(addr_params['lon'].to_f, addr_params['lat'].to_f)
      @trip.pickup_address = new_temp_addr
    end

    if params[:trip][:dropoff_address_id].blank? && !params[:trip_dropoff_google_address].blank?
      addr_params = JSON(params[:trip_dropoff_google_address])
      new_temp_addr = TempAddress.new(addr_params.select{|x| TempAddress.allowable_params.include?(x)})
      new_temp_addr.the_geom = RGeo::Geographic.spherical_factory(srid: 4326).point(addr_params['lon'].to_f, addr_params['lat'].to_f)
      @trip.dropoff_address = new_temp_addr
    end
  end
end
