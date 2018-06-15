class MessageTemplate < ApplicationRecord
  belongs_to :provider

  def self.by_provider(provider)
    hidden_ids = HiddenLookupTableValue.hidden_ids self.table_name, provider.try(:id)
    where.not(id: hidden_ids).where("provider_id is NULL or provider_id = ?", provider.try(:id))
  end
end
