FactoryBot.define do
  factory :trip_result do
    code { Faker::Lorem.words(2).join(' ') }
    name { Faker::Lorem.words(2).join(' ') }
    description "result_description"
  end

end
