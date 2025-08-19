FactoryBot.define do
  factory :sensor_log do
    association :sensor
    temperature { rand(20.0..80.0) }
    humidity    { rand(30.0..90.0) }
    detected_at { Time.current }
  end
end
