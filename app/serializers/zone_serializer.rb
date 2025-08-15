class ZoneSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :city, :latitude, :longitude,
             :created_at, :sensors_count, :cameras_count
end
