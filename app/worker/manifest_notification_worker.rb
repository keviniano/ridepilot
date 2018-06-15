class ManifestNotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform(run_id)
    Rails.logger.info "ManifestNotificationWorker#perform, run_id=#{run_id}"

    if run_id
      ActionCable.server.broadcast "manifest_channel_#{run_id}", {id: run_id, action: 'ManifestChange'}
    end
  end
end
