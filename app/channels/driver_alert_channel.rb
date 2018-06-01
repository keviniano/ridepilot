class DriverAlertChannel < ApplicationCable::Channel
  def subscribed
    stream_from "driver_alert_channel_#{params[:provider_id]}_#{params[:driver_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
