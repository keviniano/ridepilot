FactoryBot.define do
  factory :vehicle_type do
    name { Faker::Lorem.words(2).join(' ') }
    provider 
  end

end
