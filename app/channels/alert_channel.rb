class AlertChannel < ApplicationCable::Channel
  def subscribed
    stream_from "alert_channel_#{params[:provider_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def trigger
    EmergencyAlert.create(provider_id: params[:provider_id], sender: current_user)
  end

  def dismiss(data)
    alert = EmergencyAlert.find_by(id: data['id'])
    if alert
      reader = User.find_by_id(data['reader_id'])
      if reader 
        alert.reader = reader
        alert.read_at = DateTime.now
        alert.save(validate: false)

        EmergencyAlertDismissWorker.perform_async(alert.id)
      end
    end
  end
end
