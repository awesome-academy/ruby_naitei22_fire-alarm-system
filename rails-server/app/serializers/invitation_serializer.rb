class InvitationSerializer < ActiveModel::Serializer
  attributes :code, :purpose, :used, :expires_at, :created_at
end
