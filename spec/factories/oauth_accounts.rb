FactoryBot.define do
  factory :oauth_account do
    provider { "MyString" }
    uid { "MyString" }
    user { nil }
  end
end
