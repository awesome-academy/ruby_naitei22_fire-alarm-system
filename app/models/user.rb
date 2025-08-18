class User < ApplicationRecord
  ROLES = %i(supervisor admin).freeze
  NAME_MAXIMUM = 50
  PASSWORD_MINIMUM = 6
  FORGOT_PASSWORD_EXPIRATION = 2.hours

  has_secure_password

  enum role: {supervisor: 0, admin: 1}

  has_many :tokens, dependent: :destroy
  has_many :zones, dependent: :destroy
  has_many :invitations, dependent: :destroy

  scope :newest, ->{order(created_at: :desc)}

  belongs_to :admin, class_name: User.name, optional: true
  has_many :supervisors,
           class_name: User.name,
           foreign_key: "admin_id",
           dependent: :nullify,
           inverse_of: :admin

  validates :name, presence: true, length: {maximum: NAME_MAXIMUM}
  validates :email,
            presence: true,
            uniqueness: {case_sensitive: false},
            format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :role,
            presence: true,
            inclusion: {in: roles.keys}
  validates :password,
            presence: true,
            length: {minimum: PASSWORD_MINIMUM},
            allow_nil: true,
            if: ->{new_record? || !password.nil?}

  before_validation :clear_admin_id_if_admin
  validate :admin_must_not_have_an_admin
  validate :supervisor_must_have_an_admin, on: :create

  def generate_password_reset_token!
    self.password_reset_token = SecureRandom.urlsafe_base64
    self.password_reset_sent_at = Time.current
    save!
  end

  def send_password_reset_email!
    UserMailer.password_reset(self).deliver_later
  end

  def password_reset_token_valid?
    if password_reset_sent_at.present?
      password_reset_sent_at > FORGOT_PASSWORD_EXPIRATION.ago
    else
      false
    end
  end

  def clear_password_reset_token!
    self.password_reset_token = nil
    self.password_reset_sent_at = nil
    save!
  end

  def forgot_pw_url
    base_url = ENV.fetch("FRONTEND_URL")
    "#{base_url}/reset-password?token=#{password_reset_token}"
  end

  private

  def clear_admin_id_if_admin
    self.admin_id = nil if admin?
  end

  def admin_must_not_have_an_admin
    return unless admin? && admin_id.present?

    errors.add(:admin_id, :cannot_be_set_for_admin)
  end

  def supervisor_must_have_an_admin
    return unless supervisor? && admin.nil?

    errors.add(:admin, :must_exist_for_supervisor)
  end
end
