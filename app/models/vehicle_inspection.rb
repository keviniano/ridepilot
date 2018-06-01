class VehicleInspection < ApplicationRecord
  acts_as_paranoid # soft delete
  has_paper_trail

  belongs_to :provider

  validates_presence_of :description

  scope :across_system,       -> { where(provider_id: nil) }
  scope :provider_specific,   ->(provider_id) { where(provider_id: provider_id) }

  def self.by_provider(provider)
    hidden_ids = HiddenLookupTableValue.hidden_ids self.table_name, provider.try(:id)
    where.not(id: hidden_ids).where("provider_id is NULL or provider_id = ?", provider.try(:id))
  end
end
