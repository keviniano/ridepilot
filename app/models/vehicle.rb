class Vehicle < ActiveRecord::Base
  include RequiredFieldValidatorModule 
  include Inactivateable
  include PublicActivity::Common

  acts_as_paranoid # soft delete
  
  OWNERSHIPS = [:agency, :volunteer].freeze

  has_paper_trail

  belongs_to :default_driver, -> { with_deleted }, :class_name => "Driver"
  belongs_to :provider, -> { with_deleted }
  belongs_to :garage_address, -> { with_deleted }, class_name: 'GarageAddress', foreign_key: 'garage_address_id'
  accepts_nested_attributes_for :garage_address, update_only: true
  
  has_one :device_pool_driver, :dependent => :destroy
  has_one :device_pool, :through => :device_pool_driver

  belongs_to :vehicle_maintenance_schedule_type
  
  has_many :documents, as: :documentable, dependent: :destroy, inverse_of: :documentable
  has_many :runs, inverse_of: :vehicle # TODO add :dependent rule
  has_many :trips, through: :runs
  has_many :vehicle_maintenance_events, dependent: :destroy, inverse_of: :vehicle
  has_many :vehicle_warranties, dependent: :destroy, inverse_of: :vehicle

  # We must specify :delete_all in order to avoid the before_destroy hook. See
  # the RecurringComplianceEvent concern for more details. 
  # TODO Look into using `#mark_for_destruction` and `#marked_for_destruction?`
  has_many :vehicle_maintenance_compliances, dependent: :delete_all, inverse_of: :vehicle

  validates :provider, presence: true
  validates :name, presence: true, uniqueness: { :case_sensitive => false, scope: :provider, message: "should be unique" }
  validates :license_plate, uniqueness: { :case_sensitive => false, scope: :provider, message: "should be unique" }, allow_nil: true, allow_blank: true
  validates :vin, uniqueness: { :case_sensitive => false, scope: :provider, message: "should be unique" }, length: {is: 17},
    format: {with: /\A[^ioq]*\z/i}, allow_nil: true, allow_blank: true
  validates_date :registration_expiration_date, allow_blank: true
  validates :seating_capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :mobility_device_accommodations, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :ownership, inclusion: { in: OWNERSHIPS.map(&:to_s), allow_blank: true }
  validates :initial_mileage, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10000000 }
  validate  :valid_phone_number
  
  scope :for_provider,  -> (provider_id) { where(provider_id: provider_id) }
  scope :reportable,    -> { where(reportable: true) }
  scope :default_order, -> { order(:name) }

  def self.unassigned(provider)
    for_provider(provider).reject { |vehicle| vehicle.device_pool.present? }
  end

  def last_odometer_reading
    associated_runs = runs.where().not(end_odometer: nil)
    # if no existing run has logged odometer, then use initial mileage
    last_odometer = if associated_runs.empty?
      initial_mileage
    else
      associated_runs.last.try(:end_odometer)
    end

    last_odometer.to_i
  end

  def compliant?(as_of: Date.current)
    vehicle_maintenance_compliances.overdue(as_of: as_of).empty?
  end  

  def expired?(as_of: Date.current)
    vehicle_warranties.expired(as_of: as_of).any?
  end
  
  def open_seating_capacity(start_time, end_time, ignore: nil)
    seating_capacity - (trips.incomplete.during(start_time, end_time) - Array(ignore)).collect(&:trip_size).flatten.compact.sum if seating_capacity
  end

  def open_mobility_device_capacity(start_time, end_time, ignore: nil)
    mobility_device_accommodations - (trips.incomplete.during(start_time, end_time) - Array(ignore)).collect(&:mobility_device_accommodations).flatten.compact.sum if mobility_device_accommodations
  end

  private

  def valid_phone_number
    util = Utility.new
    if garage_phone_number.present?
      errors.add(:garage_phone_number, 'is invalid') unless util.phone_number_valid?(garage_phone_number) 
    end
  end
end
