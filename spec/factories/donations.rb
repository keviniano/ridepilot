FactoryBot.define do
  factory :donation do
    customer
    trip nil
    user
    date "2015-09-15 17:17:55"
    amount 1.5
    notes "MyText"
    deleted_at "2015-09-15 17:17:55"
  end

end
