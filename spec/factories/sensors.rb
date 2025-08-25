FactoryBot.define do
  factory :sensor do
    sequence(:name) { |n| "Sensor #{n}" }
    location        { Faker::Address.street_address }
    threshold       { 50.0 }
    sensitivity     { 5 }
    status          { :active }
    latitude        { Faker::Address.latitude }
    longitude       { Faker::Address.longitude }
    association :zone
  end
end
