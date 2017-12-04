class RepeatingTripRidershipMobility < RidershipMobilityMapping
  belongs_to :trip, foreign_key: :host_id
end
