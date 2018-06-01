class RunDistanceCalculationWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform(run_id)
    Rails.logger.info "RunDistanceCalculationWorker#perform, Run ID = #{run_id}"
    begin
      RunStatsCalculator.new(run_id).process_distance
    rescue Exception => ex
      puts ex.message
    end
  end
end
