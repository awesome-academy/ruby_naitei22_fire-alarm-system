FactoryBot.define do
    factory :camera do
        sequence(:name) { |n| "Camera #{n}" }
        url { "rtsp://fake.stream/cam#{SecureRandom.hex(4)}" }
        zone
        status { :online }
        is_detecting { false }
    end
end
