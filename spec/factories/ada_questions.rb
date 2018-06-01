FactoryBot.define do
  factory :ada_question do
    name  { Faker::Lorem.words(2).join(' ') }
  end

end
