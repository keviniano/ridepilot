FactoryBot.define do
  factory :role do
    user
    provider { user.current_provider }
    level 100
  end
end
