FactoryBot.define do
  factory :repeating_itinerary do
    time "2018-01-16 8:00:00"
    eta "2018-01-16 8:20:00"
    travel_time 1200
    address 
    association :run, factory: :repeating_run
    association :trip , factory: :repeating_trip
    leg_flag 1
  end

end
