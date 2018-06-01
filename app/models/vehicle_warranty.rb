class VehicleWarranty < ApplicationRecord
  include DocumentAssociable
  has_paper_trail

  belongs_to :vehicle, inverse_of: :vehicle_warranties
  
  validates_presence_of :vehicle, :description
  validates_date :expiration_date
  
  scope :expired, -> (as_of: Date.current) { where("expiration_date < ?", as_of) }
  scope :expiring_soon, -> (as_of: Date.current, through: nil) { where(expiration_date: as_of..(through || as_of + 6.days)) }
  scope :expiration_date_range,  -> (start_date, end_date) { where("expiration_date >= ? and expiration_date < ?", start_date, end_date) }
  scope :for_vehicle, -> (vehicle_id) { where(vehicle_id: vehicle_id) }
  scope :default_order, -> { order(:expiration_date) }

  def expired?
    expiration_date < Date.current
  end
end
