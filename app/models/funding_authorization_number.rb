class FundingAuthorizationNumber < ActiveRecord::Base
  belongs_to :funding_source
  belongs_to :customer, inverse_of: :funding_authorization_numbers
  
  def self.parse(fundingn_number_hash, customer)
    fundingn_number_hash.new({
      number: fundingn_number_hash[:number],
      contact_info: travel_training_hash[:contact_info],
      funding_source_id: travel_training_hash[:funding_source_id],
      customer: customer
    })
  end
end
