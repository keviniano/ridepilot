FactoryBot.define do
  factory :booking_user do
    user 
    url { Faker::Internet.url }
    token SecureRandom.uuid
  end

end
