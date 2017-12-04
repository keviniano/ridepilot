class TripRidershipMobility < RidershipMobilityMapping
  belongs_to :trip, foreign_key: :host_id
end
