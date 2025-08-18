class AlertSerializer < ActiveModel::Serializer
  attributes :id, :message, :origin, :status, :created_at, :image_url,
             :via_email

  belongs_to :user
  belongs_to :zone

  attribute :sensor do
    object.owner if object.owner_type == Sensor.name
  end

  attribute :camera do
    object.owner if object.owner_type == Camera.name
  end
end
