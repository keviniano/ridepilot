class ChatWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform(message_id)
    Rails.logger.info "ChatWorker#perform"
    message = RoutineMessage.find_by_id message_id
    if message
      ActionCable.server.broadcast "chat_channel_#{message.provider_id}_#{message.driver_id}", {
        sender_id: message.sender_id, 
        sender_name: message.sender.try(:display_name),
        message: message.body, 
        action: 'CreateMessage'
      }
    end
  end
end
