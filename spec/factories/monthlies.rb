FactoryBot.define do
  factory :monthly do
    start_date { Time.now }
    provider
    funding_source
  end
end
