class RoutineMessage < Message 
  after_create_commit :broadcast_chat
  
  private

  def broadcast_chat
    ChatWorker.perform_async(self.id)
  end
end