class ChatAlertChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_alert_channel_#{params[:run_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def trigger
  end

  def dismiss
  end
end
