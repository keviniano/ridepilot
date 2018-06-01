class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_channel_#{params[:provider_id]}_#{params[:driver_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def create(data)
    puts data
    RoutineMessage.create(provider_id: params[:provider_id], sender: current_user, body: data["body"], driver_id: data["driver_id"])
  end
end
