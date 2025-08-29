FactoryBot.define do
  factory :camera do
    sequence(:name) { |n| "Camera Giám Sát #{n}" }

    url { Faker::Internet.url }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    status { :online }

    is_detecting { true }

    association :zone

    trait :offline do
      status { :offline }
    end

    trait :recording do
      status { :recording }
    end

    trait :error do
      status { :error }
    end

    trait :not_detecting do
      is_detecting { false }
    end
  end
end
