class Alert < ApplicationRecord
  ALERT_PERMIT = %i(
    message origin status via_email owner_id owner_type zone_id
  ).freeze

  enum status: {pending: 0, resolved: 1, ignored: 2}
  enum origin: {sensor_threshold: 0, sensor_error: 1, ml_detection: 2,
                manual_input: 3}

  has_one_attached :snapshot
  belongs_to :owner, polymorphic: true
  belongs_to :zone
  belongs_to :user, optional: true

  validates :message, presence: true
  validates :owner, presence: true
  validates :zone, presence: true

  scope :newest, ->{order(created_at: :desc)}
  scope :with_status, (lambda do |status|
    where(status:) if status.present? && statuses.key?(status)
  end)
  scope :in_date_range, lambda {|start_date, end_date|
    return unless start_date.present? && end_date.present?

    begin
      start_time = Time.zone.parse(start_date.to_s).beginning_of_day
      end_time = Time.zone.parse(end_date.to_s).end_of_day
      where(created_at: start_time..end_time)
    rescue ArgumentError
      all
    end
  }

  def self.pending_count
    pending.count
  end

  def notification_recipient
    zone.user
  end
end
