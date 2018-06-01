class Fare < ApplicationRecord
  enum fare_type: [:free, :donation, :payment]

  def is_free?
    !fare_type || fare_type == 'free'
  end

  def is_donation?
    fare_type == 'donation'
  end

  def is_payment?
    fare_type == 'payment'
  end
end
