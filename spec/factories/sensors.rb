FactoryBot.define do
    factory :sensor do
        sequence(:name) { |n| "Sensor #{n}" }
        location { Faker::Address.street_address }
        status { :active }
        threshold { 50.0 }
        sensitivity { 5 }
        zone
    end
end
