class TripDistanceCalculationWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default'

  def perform(trip_id)
    Rails.logger.info "TripDistanceCalculationWorker#perform, Trip ID = #{trip_id}"
    trip = Trip.find_by_id(trip_id)
    begin
      trip.update_drive_distance!
    rescue Exception => ex
      puts ex.message
    end
  end
end
