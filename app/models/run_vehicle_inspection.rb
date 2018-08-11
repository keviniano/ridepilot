class RunVehicleInspection < ApplicationRecord
  belongs_to :run
  belongs_to :vehicle_inspection, -> { with_deleted }

  scope :for_date_range,     -> (from_date, to_date) { where(updated_at: from_date.beginning_of_day..(to_date - 1.day).end_of_day) } 
end
