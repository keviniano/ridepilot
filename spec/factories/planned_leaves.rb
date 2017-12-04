FactoryGirl.define do
  factory :planned_leaves, :class => 'PlannedLeave' do
    start_date "2017-11-22 00:00:00"
    end_date "2017-11-22 00:00:00"
    reason "MyText"
    association :leavable, factory: :driver
  end

end
