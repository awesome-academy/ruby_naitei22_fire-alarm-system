FactoryBot.define do
    factory :sensor_log do
        sensor
        temperature { rand(20.0..40.0).round(1) }
        humidity { rand(30..70) }
    end
end
