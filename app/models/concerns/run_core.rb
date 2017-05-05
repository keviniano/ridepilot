require 'active_support/concern'

module RunCore
  extend ActiveSupport::Concern

  included do
    belongs_to :provider, -> { with_deleted }
    belongs_to :driver, -> { with_deleted }
    belongs_to :vehicle, -> { with_deleted }

    validates                 :name, presence: true, uniqueness: { scope: :date, message: "should be unique per day" }
    #validates                 :driver, presence: true
    validates                 :provider, presence: true
    validates                 :vehicle, presence: true
    validates_date            :date
    validates_datetime        :scheduled_start_time, allow_blank: true
    validates_datetime        :scheduled_end_time, after: :scheduled_start_time, allow_blank: true

    scope :for_paid_driver,        -> { where(paid: true) }
    scope :for_volunteer_driver,   -> { where(paid: false) }
    scope :for_provider,           -> (provider_id) { where(provider_id: provider_id) }
    scope :for_vehicle,            -> (vehicle_id) { where(vehicle_id: vehicle_id) }
    scope :for_driver,             -> (driver_id) { where(driver_id: driver_id) }
    scope :has_scheduled_time,     -> { where.not(scheduled_start_time: nil).where.not(scheduled_end_time: nil) }
    

    delegate :name, to: :driver, prefix: :driver, allow_nil: true
  end

  def cab=(value)
    @cab = value
  end

  def vehicle_name
    vehicle.name if vehicle.present?
  end
  
  def label
    if @cab
      "Cab"
    else
      !name.blank? ? name: "#{vehicle_name}: #{driver.try :name} #{scheduled_start_time.try :strftime, "%I:%M%P"}".gsub( /m$/, "" )
    end
  end
  
  def as_json(options)
    { :id => id, :label => label }
  end
  
  
  module ClassMethods
  end 
end
