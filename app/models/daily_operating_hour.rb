class DailyOperatingHour < ActiveRecord::Base
  include OperatingHourCore
  validates_presence_of :date

  scope :for_date, -> (date) { where(date: date) }

  default_scope -> { order :date }
end
