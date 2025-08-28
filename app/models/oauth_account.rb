class OauthAccount < ApplicationRecord
  belongs_to :user

  def self.from_omniauth auth
    find_or_initialize_by(provider: auth.provider,
                          uid: auth.uid).tap do |account|
      account.email = auth.info.email
      account.name  = auth.info.name
      account.save!
    end
  end
end
