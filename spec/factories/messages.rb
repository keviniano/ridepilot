FactoryBot.define do
  factory :message do
    type "RoutineMessage"
    body "MyText"
    association :reader, factory: :user
    association :sender, factory: :user
    read_at "2018-05-24 14:44:00"
  end
end
