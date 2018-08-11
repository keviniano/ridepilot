class ChatReadReceipt < ApplicationRecord
  belongs_to :message
  belongs_to :run
  belongs_to :read_by, class_name: 'User', foreign_key: :read_by_id

  after_create_commit :dismiss_chat_alert
  
  scope :for_today, -> { where(created_at: Date.today.beginning_of_day..Date.today.end_of_day) }
  
  private

  def dismiss_chat_alert
    ChatAlertDismissWorker.perform_async(self.id)
  end
end
