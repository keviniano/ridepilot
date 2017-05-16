FactoryGirl.define do
  factory :run do
    name { Faker::Lorem.words(2).join(' ') }
    vehicle
    driver
    provider
    today

    trait :scheduled do
      scheduled_start_time "10:00 AM"
      scheduled_end_time "12:30 PM"
    end

    trait :completed do
      scheduled
      start_odometer 100
      end_odometer 200
    end

    trait :last_week do
      date { Date.today - 1.week }
    end

    trait :two_days_ago do
      date { Date.today - 2.days }
    end

    trait :yesterday do
      date { Date.yesterday }
    end

    trait :today do
      date { Date.today }
    end

    trait :tomorrow do
      date { Date.tomorrow }
    end

    trait :next_week do
      date { Date.today + 1.week }
    end

  end
end
