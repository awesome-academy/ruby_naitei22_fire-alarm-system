require 'rails_helper'

RSpec.describe Zone, type: :model do
  let!(:user) { create(:user) }
  let!(:zone_with_city) { create(:zone, city: 'Hà Nội', latitude: nil, longitude: nil, user: user) }
  let!(:zone_with_lat_long) do 
    create(:zone, city: "Hà Nội", latitude: 21.028511, longitude: 105.804818, user: user)
  end
  let!(:zone_with_both) { create(:zone, city: 'Hồ Chí Minh', latitude: 10.7769, longitude: 106.7019, user: user) }
  let!(:zone_without_location) { create(:zone, city: "HCM", latitude: nil, longitude: nil, user: user) }
  let!(:zone_with_active_sensor) { create(:zone, user: user) }
  let!(:zone_with_inactive_sensor) { create(:zone, user: user) }
  
  before do
    create(:sensor, zone: zone_with_active_sensor, status: :active)
    create(:sensor, zone: zone_with_inactive_sensor, status: :inactive)
  end

  context 'associations' do
    it 'should belong to a user' do
      expect(Zone.new(user: user)).to respond_to(:user)
    end

    it 'should have many sensors' do
      expect(Zone.new).to respond_to(:sensors)
    end

    it 'should have many cameras' do
      expect(Zone.new).to respond_to(:cameras)
    end

    it 'should have many alerts' do
      expect(Zone.new).to respond_to(:alerts)
    end
  end


  context 'dependent: :destroy' do
    let!(:zone) { create(:zone, user: user) }

    it 'destroys associated sensors when zone is destroyed' do
      create_list(:sensor, 3, zone: zone)
      expect { zone.destroy }.to change { Sensor.count }.by(-3)
    end

    it 'destroys associated cameras when zone is destroyed' do
      create_list(:camera, 2, zone: zone)
      expect { zone.destroy }.to change { Camera.count }.by(-2)
    end

    it 'destroys associated alerts when zone is destroyed' do
      create_list(:alert, 4, zone: zone)
      expect { zone.destroy }.to change { Alert.count }.by(-4)
    end
  end

context 'scopes' do
  describe '.sorted_by_name' do
    it 'returns zones sorted by name in ascending order' do
      zone_c = create(:zone, name: 'C Zone')
      zone_a = create(:zone, name: 'A Zone')
      zone_b = create(:zone, name: 'B Zone')

      expect(Zone.where(id: [zone_a.id, zone_b.id, zone_c.id]).sorted_by_name).to eq([zone_a, zone_b, zone_c])
    end
  end

  describe '.filter_and_sort' do
    it 'sorts zones by name when params[:sort] is "name"' do
      zone_c = create(:zone, name: 'C Zone')
      zone_a = create(:zone, name: 'A Zone')
      zone_b = create(:zone, name: 'B Zone')

      params = { sort: 'name' }
      expect(Zone.where(id: [zone_a.id, zone_b.id, zone_c.id]).filter_and_sort(params)).to eq([zone_a, zone_b, zone_c])
    end
  end

  describe '.with_location' do
    it 'returns zones with city or lat/long' do
      zone_with_city = create(:zone, city: 'Hà Nội', latitude: nil, longitude: nil)
      zone_with_lat_long = create(:zone, city: 'Hà Nội', latitude: 21.0, longitude: 105.8)
      zone_without_location = build(:zone, city: '', latitude: nil, longitude: nil)
      zone_without_location.save(validate: false)

      zones_with_location = Zone.with_location
      expect(zones_with_location).to include(zone_with_city, zone_with_lat_long)
      expect(zones_with_location).not_to include(zone_without_location)
    end
  end

  describe '.with_active_sensors' do
    it 'returns only zones that have active sensors' do
      zone_with_active_sensor = create(:zone)
      create(:sensor, zone: zone_with_active_sensor, status: :active)
      zone_with_inactive_sensor = create(:zone)
      create(:sensor, zone: zone_with_inactive_sensor, status: :inactive)

      expect(Zone.with_active_sensors).to include(zone_with_active_sensor)
      expect(Zone.with_active_sensors).not_to include(zone_with_inactive_sensor)
    end
  end
end
end
