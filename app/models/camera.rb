class Camera < ApplicationRecord
  enum status: {ONLINE: 0, OFFLINE: 1, RECORDING: 2, ERROR: 3}

  belongs_to :zone
  has_many :alerts, dependent: :nullify
end
