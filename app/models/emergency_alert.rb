class EmergencyAlert < Message
  before_create :update_body
  after_create_commit :broadcast_alert

  def message
    "Driver #{sender.display_name} has an emergency. Please respond immediately!"
  end

  private

  def update_body
    self.body = self.message
  end

  def broadcast_alert
    EmergencyAlertWorker.perform_async(self.id)
  end
end