FactoryBot.define do
  factory :user do
    sequence(:name)  { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password         { "password" }

    # mặc định: admin (vì enum chỉ có :admin, :supervisor)
    role { :admin }

    trait :admin do
      role { :admin }
    end

    trait :supervisor do
      role { :supervisor }
      after(:build) do |user|
        user.admin ||= create(:user, :admin)
      end
    end
  end
end
