FactoryBot.define do
    factory :user do
        name { Faker::Name.name }
        sequence(:email) { |n| "test#{n}@example.com" }
        password { "password123" }
        is_active { true }

        trait :admin do
            role { :admin }
        end

        trait :supervisor do
            role { :supervisor }
            transient do
                admin { User.find_by(role: :admin) || create(:user, :admin) }
            end

            after(:build) do |user, evaluator|
                user.admin = evaluator.admin
            end
        end
    end
end
