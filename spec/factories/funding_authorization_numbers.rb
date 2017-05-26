FactoryGirl.define do
  factory :funding_authorization_number do
    customer
    number "MyString"
    funding_source nil
    contact_info "MyText"
  end

end
