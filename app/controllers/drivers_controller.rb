class DriversController < ApplicationController
  load_and_authorize_resource except: [:delete_photo]

  def index
    @drivers = @drivers.default_order.for_provider(current_provider.id)
  end

  def show
    prep_edit(readonly: true)
  end

  def new
    @driver.provider = current_provider
    prep_edit
  end

  def edit
    prep_edit
  end

  def update
    new_attrs = driver_params
    is_alt_address_blank = check_blank_alt_address
    if is_alt_address_blank
      prev_alt_address = @driver.alt_address
      @driver.alt_address_id = nil
      new_attrs.except!(:alt_address_attributes)
    end

    new_attrs.except!(:photo_attributes) if new_attrs[:photo_attributes].blank?

    @driver.attributes = new_attrs
    
    if !@driver.is_all_valid?(current_provider_id)
      prep_edit
      render action: :edit
    else
      begin      
        Driver.transaction do
          @driver.save!
          prev_alt_address.destroy if is_alt_address_blank && prev_alt_address.present?
          create_or_update_hours!
        end
        redirect_to @driver, notice: 'Driver was successfully updated.'
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug e.message
        prep_edit
        render action: :edit
      end
    end
  end

  def create
    new_attrs = driver_params
    is_alt_address_blank = check_blank_alt_address
    if is_alt_address_blank
      new_attrs.except!(:alt_address_attributes)
    end

    @driver.attributes = new_attrs
    @driver.alt_address = nil if is_alt_address_blank

    @driver.provider = current_provider
    if !@driver.is_all_valid?(current_provider_id)
      prep_edit
      render action: :new
    else
      begin
        Driver.transaction do
          @driver.save!
          create_or_update_hours!
        end
        redirect_to @driver, notice: 'Driver was successfully created.'
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.debug e.message
        prep_edit
        render action: :new
      end
    end
  end

  def destroy
    @driver.destroy
    redirect_to drivers_path, notice: 'Driver was successfully deleted.'
  end

  def delete_photo
    @driver = Driver.find(params[:id])

    authorize! :update, @driver

    @driver.photo.try(:destroy!)

    redirect_to @driver, :notice => "Photo has been deleted."
  end

  private
  
  def prep_edit(readonly: false)
    @readonly = readonly
    
    @available_users = @driver.provider.users - User.drivers(@driver.provider)
    @available_users << @driver.user if @driver.user
    @available_users = @available_users.sort_by(&:name_with_username) 
    
    @hours = @driver.hours_hash

    @start_hours = OperatingHours.available_start_times
    @end_hours = OperatingHours.available_end_times
    
    @driver.address ||= @driver.build_address
    @driver.alt_address ||= @driver.build_alt_address 
    
    unless readonly
      @driver.build_photo unless @driver.photo.present?
    end
  end
  
  def driver_params
    params.require(:driver).permit(
      :active, 
      :paid, 
      :name, 
      :email, 
      :user_id,
      :phone_number,
      :alt_phone_number,
      photo_attributes: [:image],
      :address_attributes => [
        :address,
        :building_name,
        :city,
        :name,
        :provider_id,
        :state,
        :zip,
        :notes
      ],
      :alt_address_attributes => [
        :address,
        :building_name,
        :city,
        :name,
        :provider_id,
        :state,
        :zip,
        :notes
      ]
    )
  end
  
  def create_or_update_hours!
    OperatingHoursProcessor.new(@driver, {
      hours: params[:hours],
      start_hour: params[:start_hour],
      end_hour: params[:end_hour]
      }).process!
  end

  def check_blank_alt_address
    alt_address_params = driver_params[:alt_address_attributes]
    is_blank = true
    alt_address_params.keys.each do |key|
      next if key.to_s == 'provider_id'
      unless alt_address_params[key].blank?
        is_blank = false
        break
      end
    end if alt_address_params

    is_blank
  end
end
