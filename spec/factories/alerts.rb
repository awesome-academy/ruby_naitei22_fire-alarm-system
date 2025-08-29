FactoryBot.define do
  factory :alert do
    message     { "Temperature exceeded threshold!" }
    origin      { :sensor_threshold }
    status      { :pending }
    via_email   { true }
    association :zone
    
    owner { association :sensor, zone: zone }

    trait :for_camera do
      owner { association :camera, zone: zone }
      origin { :ml_detection }
    end
  end
end
