class AddressGroup < ActiveRecord::Base
  belongs_to :provider

  scope :by_provider, -> (provider) { where(provider: provider) }
end
