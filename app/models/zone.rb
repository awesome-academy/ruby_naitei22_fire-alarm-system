class Zone < ApplicationRecord
  belongs_to :user
  has_many :sensors, dependent: :destroy
  has_many :cameras, dependent: :destroy
  has_many :alerts, dependent: :destroy
  validates :name,
            presence: true,
            uniqueness: {
              scope: :user_id,
              message: I18n.t("zones.errors.name_uniqueness")
            }
  validates :user, presence: true
  scope :with_location, (lambda do
    where.not(city: nil)
         .or(where.not(latitude: nil, longitude: nil))
  end)
  scope :with_active_sensors, (lambda do
    joins(:sensors).where(sensors: {status: :active})
  end)

  def self.ransackable_attributes _auth_object = nil
    %w(name description city created_at sensors_count cameras_count)
  end

  def self.ransackable_associations _auth_object = nil
    %w(user sensors cameras)
  end
end
