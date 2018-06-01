FactoryBot.define do
  factory :gps_location do
    latitude 1.5
    longitude 1.5
    bearing 1.5
    speed 1.5
    log_time "2018-03-26 10:43:04"
    accuracy 1
    provider
    run
    itinerary_id 1
  end
end
