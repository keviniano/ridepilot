class MobilityCapacity < Capacity
  after_initialize :set_defaults
  
  belongs_to :mobility, foreign_key: :host_id

  private

  def set_defaults
    self.capacity = 0 if self.capacity.blank?
  end
end
