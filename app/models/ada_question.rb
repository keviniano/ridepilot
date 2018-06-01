class AdaQuestion < ApplicationRecord
  belongs_to :provider

  has_many   :customer_ada_questions, dependent: :destroy
  
  validates :name, presence: true, uniqueness: { :case_sensitive => false, scope: :provider }

  scope :by_provider, ->(provider_id) { where(provider_id: provider_id) }
end
