class ChatAlertDismissWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'critical'

  def perform(receipt_id)
    Rails.logger.info "ChatAlertDismissWorker#perform"
    receipt = ChatReadReceipt.find_by_id receipt_id
    if receipt
      ActionCable.server.broadcast "chat_alert_channel_#{receipt.run_id}", {
        dismiss: true,
        action: 'DismissChatAlert',
        message_id: receipt.message_id,
        read_by_id: receipt.read_by_id,
        id: receipt_id
      }
    end
  end
end
