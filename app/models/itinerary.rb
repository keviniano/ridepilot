class Itinerary < ActiveRecord::Base
  include ItineraryCore
  
  belongs_to :trip 
  belongs_to :run
end