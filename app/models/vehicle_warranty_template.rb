class VehicleWarrantyTemplate < ApplicationRecord
  belongs_to :provider

  validates :name, presence: true, uniqueness: { :case_sensitive => false, scope: :provider }

  scope :by_provider, ->(provider_id) { where(provider_id: provider_id) }

end
