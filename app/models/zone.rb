# app/models/zone.rb
class Zone < ApplicationRecord
  SORT_BY_NAME = "name".freeze

  belongs_to :user
  has_many :sensors, dependent: :destroy
  has_many :cameras, dependent: :destroy
  has_many :alerts, dependent: :destroy

  validates :name, presence: true, length: {maximum: 255}
  validate :location_is_present

  validates :latitude, numericality: {
    greater_than_or_equal_to: -90,
    less_than_or_equal_to: 90,
    allow_nil: true
  }
  validates :longitude, numericality: {
    greater_than_or_equal_to: -180,
    less_than_or_equal_to: 180,
    allow_nil: true
  }

  scope :sorted_by_name, ->{order(name: :asc)}

  scope :filter_and_sort, lambda {|params|
    result = all

    result = result.where(city: params[:city]) if params[:city].present?

    result = result.sorted_by_name if params[:sort] == SORT_BY_NAME
    result
  }

  scope(:with_location, lambda do
    where.not(city: [nil, ""]).or(
      where.not(latitude: nil).where.not(longitude: nil)
    )
  end)

  scope(:with_active_sensors, lambda do
    joins(:sensors).where(sensors: {status: :active})
  end)

  private

  def location_is_present
    return unless city.blank? && (latitude.blank? || longitude.blank?)

    errors.add(:base,
               "A zone must have a city or both latitude and longitude")
  end
end
