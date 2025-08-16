class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :phone, :address, :role, :is_active,
             :created_at, :updated_at
  attribute :role do
    object.role.upcase
  end
end
