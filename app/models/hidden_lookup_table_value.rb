class HiddenLookupTableValue < ApplicationRecord
  has_paper_trail
  
  belongs_to :provider

  validates :provider, presence: true
  validates :table_name, presence: true
  validates :value_id, presence: true

  def self.hidden_ids(lookup_table_name, a_provider_id)
    where(table_name: lookup_table_name, provider_id: a_provider_id).pluck(:value_id)
  end

  def self.show_value(lookup_table_name, a_provider_id, model_id)
    where(table_name: lookup_table_name, provider_id: a_provider_id, value_id: model_id).delete_all
  end

  def self.hide_value(lookup_table_name, a_provider_id, model_id)
    where(table_name: lookup_table_name, provider_id: a_provider_id, value_id: model_id).first_or_create
  end
end
