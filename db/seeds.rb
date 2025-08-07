require "faker"

def run_seeds
  if Rails.env.production?
    abort("Refusing to run seeds in production environment.")
  end

  cleanup_database
  create_users_with_faker
  create_zones_and_cameras_with_faker
end

def cleanup_database
  Token.destroy_all
  Invitation.destroy_all
  Camera.destroy_all
  Zone.destroy_all
  User.destroy_all
end

def create_users_with_faker
  @admin = User.find_or_create_by!(email: ENV.fetch("ADMIN_EMAIL")) do |user|
    user.name = ENV.fetch("ADMIN_NAME")
    user.password = ENV.fetch("ADMIN_PASSWORD")
    user.phone = ENV.fetch("ADMIN_PHONE")
    user.address = ENV.fetch("ADMIN_ADDRESS")
    user.role = :admin
    user.is_active = true
  end

  5.times do |i|
    User.find_or_create_by!(email: "supervisor.#{i + 1}@example.com") do |user|
      user.name = Faker::Name.name
      user.password = "password123"
      user.phone = Faker::PhoneNumber.cell_phone
      user.address = Faker::Address.full_address
      user.role = :supervisor
      user.admin = @admin
      user.is_active = (i != 1)
    end
  end
  @supervisors = User.where(role: :supervisor)
end

def create_zones_and_cameras_with_faker
  3.times do |i|
    zone = Zone.find_or_create_by!(name: "Khu vực #{('A'..'Z').to_a[i]}") do |z|
      z.description = Faker::Lorem.sentence(word_count: 10)
      z.city = Faker::Address.city
      z.user = @supervisors.sample
    end

    rand(2..4).times do |j|
      Camera.find_or_create_by!(name: "Camera #{zone.name} - #{j + 1}") do |camera|
        camera.url = "rtsp://fake.stream.com/#{zone.name.parameterize}/cam#{j + 1}"
        camera.status = Camera.statuses.keys.sample
        camera.zone = zone
        camera.is_detecting = [true, false].sample
      end
    end
  end
end

run_seeds
