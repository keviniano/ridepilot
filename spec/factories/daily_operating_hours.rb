FactoryBot.define do
  factory :daily_operating_hour do
    date "2017-11-22 00:00:00"
    start_time "00:00:00"
    end_time "23:59:59"
    association :operatable, factory: :driver
  end

end
