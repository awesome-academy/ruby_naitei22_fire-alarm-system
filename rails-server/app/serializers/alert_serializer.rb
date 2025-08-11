class AlertSerializer < ActiveModel::Serializer
  attributes :id, :message, :origin, :status, :via_email, :created_at,
             :updated_at

  belongs_to :user, serializer: UserSerializer
  belongs_to :zone, serializer: ZoneSerializer
  belongs_to :owner

  attribute :snapshot_url do
    if object.snapshot.attached?
      Rails.application.routes.url_helpers.url_for(object.snapshot)
    end
  end
end
