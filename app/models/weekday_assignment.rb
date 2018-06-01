class WeekdayAssignment < ApplicationRecord
  belongs_to :repeating_trip
  belongs_to :repeating_run

  scope :for_wday, -> (wday) { where(wday: wday) }
end
