class CustomerAddressType < ApplicationRecord
  acts_as_paranoid # soft delete
  
  validates :name, presence: true, uniqueness: {case_sensitive: false, conditions: -> { where(deleted_at: nil) } }
  validates :code, presence: true, uniqueness: {case_sensitive: false, conditions: -> { where(deleted_at: nil) } }

  def self.by_provider(provider)
    hidden_ids = HiddenLookupTableValue.hidden_ids self.table_name, provider.try(:id)
    where.not(id: hidden_ids)
  end
end
