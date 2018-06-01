class PublicItinerary < ApplicationRecord
  belongs_to :itinerary, -> { with_deleted }
  belongs_to :run

  scope :finished, -> { joins(:itinerary).where.not(itineraries: {finish_time: nil}) }
  scope :non_finished, -> { joins(:itinerary).where(itineraries: {finish_time: nil}) }
end
