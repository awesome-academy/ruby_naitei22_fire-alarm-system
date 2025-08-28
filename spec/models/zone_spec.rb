require "rails_helper"

RSpec.describe Zone, type: :model do
    describe "associations" do
        it { is_expected.to belong_to(:user) }
        it { is_expected.to have_many(:sensors).dependent(:destroy) }
        it { is_expected.to have_many(:cameras).dependent(:destroy) }
        it { is_expected.to have_many(:alerts).dependent(:destroy) }
    end

    describe "scopes" do
        let!(:zone_with_city) { create(:zone, city: "Hanoi") }
        let!(:zone_with_coords) { create(:zone, city: nil, latitude: 10.0, longitude: 106.0) }
        let!(:zone_without_location) { create(:zone, city: nil, latitude: nil, longitude: nil) }

        let!(:zone_with_active_sensor) { create(:zone) }
        let!(:active_sensor) { create(:sensor, zone: zone_with_active_sensor, status: :active) }

        let!(:zone_with_inactive_sensor) { create(:zone) }
        let!(:inactive_sensor) { create(:sensor, zone: zone_with_inactive_sensor, status: :inactive) }

        describe ".with_location" do
            it "includes zones with a city" do
                expect(Zone.with_location).to include(zone_with_city)
            end

            it "includes zones with latitude and longitude" do
                expect(Zone.with_location).to include(zone_with_coords)
            end

            it "excludes zones without any location data" do
                expect(Zone.with_location).not_to include(zone_without_location)
            end
        end

        describe ".with_active_sensors" do
            it "includes zones that have at least one active sensor" do
                expect(Zone.with_active_sensors).to include(zone_with_active_sensor)
            end

            it "excludes zones that only have inactive sensors" do
                expect(Zone.with_active_sensors).not_to include(zone_with_inactive_sensor)
            end
        end
    end

    describe "Ransack configuration" do
        describe ".ransackable_attributes" do
            it "returns a whitelist of searchable attributes" do
                expected_attrs = %w[name description city created_at sensors_count cameras_count]
                expect(Zone.ransackable_attributes).to match_array(expected_attrs)
            end
        end

        describe ".ransackable_associations" do
            it "returns a whitelist of searchable associations" do
                expected_assocs = %w[user sensors cameras]
                expect(Zone.ransackable_associations).to match_array(expected_assocs)
            end
        end
    end
end
