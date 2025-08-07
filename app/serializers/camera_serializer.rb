class CameraSerializer < ActiveModel::Serializer
  attributes :id, :name, :url, :latitude, :longitude, :status,
             :is_detecting, :last_snapshot_url, :created_at

  belongs_to :zone
end
