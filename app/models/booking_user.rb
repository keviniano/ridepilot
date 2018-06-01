class BookingUser < ApplicationRecord

  belongs_to :user, -> { with_deleted }
  validates :user, presence: true

  # Token is auto-generated at database level via uuid extension
  
  acts_as_paranoid # soft delete

  has_paper_trail
end
