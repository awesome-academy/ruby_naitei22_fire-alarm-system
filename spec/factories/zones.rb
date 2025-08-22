FactoryBot.define do
    factory :zone do
        name { "Zone #{Faker::Alphanumeric.alpha(number: 3).upcase}" }
        association :user, :supervisor
    end
end
