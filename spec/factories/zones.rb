FactoryBot.define do
  factory :zone do
    sequence(:name) { |n| "Zone #{n}" }
    description     { Faker::Lorem.sentence }
    city            { Faker::Address.city }
    latitude        { Faker::Address.latitude }
    longitude       { Faker::Address.longitude }
    association :user, :supervisor
  end
end
