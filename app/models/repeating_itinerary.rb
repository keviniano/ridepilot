class RepeatingItinerary < ApplicationRecord
  include ItineraryCore

  belongs_to :trip, class_name: 'RepeatingTrip', foreign_key: 'repeating_trip_id'
  belongs_to :run, class_name: 'RepeatingRun', foreign_key: 'repeating_run_id'

  scope :for_wday, -> (wday) { where(wday: wday) }
end
