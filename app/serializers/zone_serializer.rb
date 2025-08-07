class ZoneSerializer < ActiveModel::Serializer
  attributes :id, :name, :user_id, :description, :city, :latitude, :longitude,
             :created_at
end
