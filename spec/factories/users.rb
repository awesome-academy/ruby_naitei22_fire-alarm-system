FactoryBot.define do
  factory :user do
    sequence(:name)  { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    phone            { Faker::PhoneNumber.unique.cell_phone_in_e164 }
    address          { Faker::Address.full_address }
    password_digest  { BCrypt::Password.create("password") }
    is_active        { true }
    role             { :admin }

    trait :admin do
      role { :admin }
    end

    trait :supervisor do
      role { :supervisor }

      after(:build) do |user|
        user.admin ||= User.find_by(role: :admin) || create(:user, :admin)
      end
    end

    trait :inactive do
      is_active { false }
    end
  end
end
