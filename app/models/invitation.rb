# frozen_string_literal: true

class Invitation < ApplicationRecord
  CODE_LENGTH = 8
  DEFAULT_EXPIRATION = 1.week
  PURPOSE_SIGNUP = "signup"
  VALID_PURPOSES = [PURPOSE_SIGNUP].freeze
  CODE_PREFIX = "SIGNUP"

  belongs_to :user

  before_validation :generate_unique_code, on: :create

  scope :newest, ->{order(created_at: :desc)}
  scope :unused, ->{where(used: false)}
  # rubocop:disable Layout/LineLength
  scope :not_expired, ->{where("expires_at IS NULL OR expires_at > ?", Time.current)}
  # rubocop:enable Layout/LineLength
  scope :valid, ->{unused.not_expired}
  scope :valid_for_signup, ->{valid.for_signup}
  scope :for_signup, ->{where(purpose: PURPOSE_SIGNUP)}

  validates :code, presence: true, uniqueness: {case_sensitive: false}
  validates :purpose, presence: true, inclusion: {in: VALID_PURPOSES}

  private

  def generate_unique_code
    self.code ||= loop do
      random_part = SecureRandom.alphanumeric(CODE_LENGTH).upcase
      new_code = "#{CODE_PREFIX}-#{random_part}"
      break new_code unless self.class.exists?(code: new_code)
    end
  end
end
