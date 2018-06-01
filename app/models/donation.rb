class Donation < ApplicationRecord
  has_paper_trail
  
  belongs_to :customer, -> { with_deleted }, inverse_of: :donations
  belongs_to :user, -> { with_deleted }
  belongs_to :trip, -> { with_deleted }

  validates :date, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :customer, presence: true
  validates :user, presence: true

  scope :for_date_range,     -> (start_date, end_date) { where('donations.date >= ? AND donations.date < ?', start_date.to_datetime.in_time_zone.utc, end_date.to_datetime.in_time_zone.utc) }

  def self.parse(donation_hash, customer, user)
    utility = Utility.new
    Donation.new({
      date: utility.parse_date(donation_hash[:date]),
      amount: donation_hash[:amount].to_f,
      notes: donation_hash[:notes],
      customer: customer,
      user: user
      })
  end
end
