class CapacityType < ActiveRecord::Base
  acts_as_paranoid # soft delete
  belongs_to :provider
  
  validates_presence_of :name
  validates_length_of :name, minimum: 2
  validate :name_uniqueness

  def self.by_provider(provider)
    hidden_ids = HiddenLookupTableValue.hidden_ids self.table_name, provider.try(:id)
    where.not(id: hidden_ids)
  end

  private

  def name_uniqueness
    if CapacityType.where("deleted_at is NULL and lower(name) = ? and (provider_id is NULL or provider_id = ?)", name.try(:downcase), provider_id).any?
      errors.add(:base, "Name has already been taken")
    end
  end

end
