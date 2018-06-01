FactoryBot.define do
  factory :hidden_lookup_table_value do
    provider
    table_name "MyString"
    value_id 1
  end

end
