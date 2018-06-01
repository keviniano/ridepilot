class RunVehicleInspection < ApplicationRecord
  belongs_to :run
  belongs_to :vehicle_inspection, -> { with_deleted }
end
