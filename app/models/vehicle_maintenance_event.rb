class VehicleMaintenanceEvent < ActiveRecord::Base
  include DocumentAssociable

  has_paper_trail

  belongs_to :vehicle, inverse_of: :vehicle_maintenance_events
  
  validates :vehicle, presence: true
  validates :services_performed, presence: true
  validates_date :service_date

  scope :service_date_range,  -> (start_date, end_date) { where("service_date >= ? and service_date < ?", start_date, end_date) }
  scope :for_vehicle, -> (vehicle_id) { where(vehicle_id: vehicle_id) }
  scope :default_order, -> { order(:service_date) }
end
