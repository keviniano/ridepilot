class DriverCompliance < ActiveRecord::Base
  include ComplianceCore

  has_paper_trail
  
  belongs_to :driver, inverse_of: :driver_compliances
  belongs_to :driver_requirement_template, -> { with_deleted }
  
  validates :driver, presence: true
  
  scope :for_driver, -> (driver_id) { where(driver_id: driver_id) }
end
