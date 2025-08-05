class User < ApplicationRecord
  has_secure_password

  enum role: {SUPERVISOR: 0, ADMIN: 1}

  has_many :tokens, dependent: :destroy
  has_many :zones, dependent: :destroy

  belongs_to :admin, class_name: User.name, optional: true
  has_many :supervisors, class_name: User.name, foreign_key: "admin_id",
dependent: :nullify
end
