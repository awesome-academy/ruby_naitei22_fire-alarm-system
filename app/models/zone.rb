class Zone < ApplicationRecord
  belongs_to :user
  has_many :sensors, dependent: :destroy
  has_many :cameras, dependent: :destroy
  has_many :alerts, dependent: :destroy

  scope :sorted_by_name, ->{order(name: :asc)}
end
