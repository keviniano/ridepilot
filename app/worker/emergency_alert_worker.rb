class EmergencyAlertWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'high_critical'

  def perform(alert_id)
    Rails.logger.info "EmergencyAlertWorker#perform, alert_id=#{alert_id}"

    alert = EmergencyAlert.find_by_id alert_id
    if alert
      ActionCable.server.broadcast "alert_channel_#{alert.provider_id}", {id: alert_id, provider_id: alert.provider_id, message: alert.body}
    end
  end
end
