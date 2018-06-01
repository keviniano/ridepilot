class DriverHistory < ApplicationRecord
  include DocumentAssociable
  
  has_paper_trail
  
  belongs_to :driver, inverse_of: :driver_histories

  validates_presence_of :driver, :event
  validates_date :event_date, on_or_before: -> { Date.current }
  
  scope :for_driver, -> (driver_id) { where(driver_id: driver_id) }
  scope :event_date_range,  -> (start_date, end_date) { where("event_date >= ? and event_date < ?", start_date, end_date) }
  scope :default_order, -> { order(:event_date) }
  
end
