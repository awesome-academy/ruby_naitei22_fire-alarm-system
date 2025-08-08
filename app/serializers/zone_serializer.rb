class ZoneSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :city, :latitude, :longitude
end
