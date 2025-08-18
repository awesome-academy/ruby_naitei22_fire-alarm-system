class Zone < ApplicationRecord
  SORT_BY_NAME = "name".freeze

  belongs_to :user
  has_many :sensors, dependent: :destroy
  has_many :cameras, dependent: :destroy
  has_many :alerts, dependent: :destroy

  scope :sorted_by_name, ->{order(name: :asc)}

  scope :filter_and_sort, lambda {|params|
    result = all
    result = result.sorted_by_name if params[:sort] == SORT_BY_NAME
    result
  }
  scope :with_location, (lambda do
    where.not(city: nil)
         .or(where.not(latitude: nil, longitude: nil))
  end)
  scope :with_active_sensors, (lambda do
    joins(:sensors).where(sensors: {status: :active})
  end)
end
