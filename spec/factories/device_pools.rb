require 'faker'

FactoryBot.define do
  factory :device_pool do
    name { Faker::Company.name }
    color { SecureRandom.hex(3) }
    provider
  end
end
