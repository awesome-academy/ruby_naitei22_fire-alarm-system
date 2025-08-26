require "faker"

def run_seeds
  abort("Refusing to run seeds in production environment.") if Rails.env.production?
  cleanup_database
  create_users_with_faker
  create_demo_zones_and_devices
  create_random_zones_and_sensors_with_faker
  create_sensor_logs_for_chart
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

def create_demo_zones_and_devices
  demo_zone = Zone.find_or_create_by!(name: "Khu vực Demo") do |z|
    z.description = "Khu vực để thử nghiệm camera thật và camera giả lập."
    z.city = "Hà Nội"
    z.latitude = 21.028511
    z.longitude = 105.804817
    z.user = @supervisors.first || @admin
  end

  if ENV["LIVE_CAMERA_RTSP_URL"].present?
    Camera.find_or_create_by!(name: "Camera Live (RTSP)") do |camera|
      camera.url = ENV.fetch("LIVE_CAMERA_RTSP_URL")
      camera.status = :online
      camera.zone = demo_zone
      camera.is_detecting = true
    end
  else
    puts "Skipping live camera creation: LIVE_CAMERA_RTSP_URL not set in .env"
  end

  Camera.find_or_create_by!(name: "Camera Giả Lập (Fake URL)") do |camera|
    camera.url = "rtsp://invalid.stream.url/fake-camera"
    camera.status = :online
    camera.zone = demo_zone
    camera.is_detecting = true
  end

  2.times do |k|
    Sensor.find_or_create_by!(name: "Cảm biến Demo - #{k + 1}") do |sensor|
      sensor.location = Faker::Address.street_address
      sensor.status = Sensor.statuses.keys.sample
      sensor.zone = demo_zone
      sensor.threshold = rand(30..70)
    end
  end
end

def create_random_zones_and_sensors_with_faker
  2.times do |i|
    zone_name = "Khu vực Ngẫu nhiên #{('A'..'Z').to_a[i]}"
    zone = Zone.find_or_create_by!(name: zone_name) do |z|
      z.description = Faker::Lorem.sentence(word_count: 10)
      z.city = Faker::Address.city
      z.latitude = Faker::Address.latitude
      z.longitude = Faker::Address.longitude
      z.user = @supervisors.sample
    end

    rand(2..3).times do |k|
      Sensor.find_or_create_by!(name: "Cảm biến #{zone.name} - #{k + 1}") do |sensor|
        sensor.location = Faker::Address.street_address
        sensor.status = Sensor.statuses.keys.sample
        sensor.zone = zone
        sensor.threshold = rand(30..70)
      end
    end
  end
end

def create_sensor_logs_for_chart
  interval = 1.hour
  start_time = 1.days.ago
  end_time = Time.current

  Sensor.find_each do |sensor|
    current_time = start_time
    while current_time <= end_time
      SensorLog.create!(
        sensor: sensor,
        temperature: rand(22.0..32.0).round(1),
        humidity: rand(55..85),
        created_at: current_time,
        updated_at: current_time
      )
      current_time += interval
    end
  end
  puts "Sensor logs seeded!"
end

run_seeds
