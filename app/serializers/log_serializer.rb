class LogSerializer < ActiveModel::Serializer
  attributes :id, :temperature, :humidity, :created_at, :updated_at

  belongs_to :sensor
end
