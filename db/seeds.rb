# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

Token.destroy_all
Invitation.destroy_all
User.destroy_all

admin_user = User.new(
  name:      ENV['ADMIN_NAME'],
  email:     ENV['ADMIN_EMAIL'],
  password:  ENV['ADMIN_PASSWORD'],
  password_confirmation: ENV['ADMIN_PASSWORD'], 
  phone:     ENV['ADMIN_PHONE'],
  address:   ENV['ADMIN_ADDRESS'],
  role:      :admin,
  is_active: true
)
