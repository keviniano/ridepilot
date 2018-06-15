class ManifestChannel < ApplicationCable::Channel
  def subscribed
    stream_from "manifest_channel_#{params[:run_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
