FactoryBot.define do
  factory :alert do
    message     { "Temperature exceeded threshold!" }
    origin      { :sensor_threshold }
    status      { :pending }
    via_email   { true }
    association :zone

    association :owner, factory: :sensor

    trait :for_camera do
      association :owner, factory: :camera
      origin { :ml_detection }
    end
  end
end
