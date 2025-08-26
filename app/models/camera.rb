class Camera < ApplicationRecord
  CAMERA_PERMIT = %i(
    name url zone_id latitude longitude status is_detecting
  ).freeze
  VALID_STATUSES = %w(online offline recording error).freeze
  enum status: {online: 0, offline: 1, recording: 2, error: 3}
  after_initialize :set_default_status, if: :new_record?
  belongs_to :zone, counter_cache: true
  has_many :alerts, as: :owner, dependent: :destroy

  scope :newest, ->{order(created_at: :desc)}
  scope :online_and_detecting, ->{where(is_detecting: true, status: :online)}

  validates :name, presence: true, uniqueness: {scope: :zone_id}
  validates :url, presence: true
  validates :zone_id, presence: true

  private
  def set_default_status
    self.status ||= :online
  end
end
