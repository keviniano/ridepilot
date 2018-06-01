FactoryBot.define do
  factory :customer_eligibility do
    customer 
    eligibility 
    eligible nil
    ineligible_reason nil
  end

end
