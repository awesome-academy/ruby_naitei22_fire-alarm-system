class AlertSerializer < ActiveModel::Serializer
  attributes :id, :message, :origin, :status, :via_email, :created_at,
             :updated_at
  attribute :image_url
  belongs_to :user, serializer: UserSerializer

  attribute :sensor do
    owner = object.owner
    next unless owner

    {
      id: owner.id,
      name: owner.name
    }
  end

  attribute :zone do
    zone = object.zone || object.owner&.zone
    next unless zone

    {
      id: zone.id,
      name: zone.name
    }
  end
end
