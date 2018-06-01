require 'faker'

FactoryBot.define do
  factory :funding_source do
    name  { Faker::Lorem.words(2).join(' ') }
  end
end
