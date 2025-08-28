require "rails_helper"

RSpec.describe Sensor, type: :model do
    describe "validations" do
        it { is_expected.to validate_presence_of(:name) }
        it { is_expected.to validate_presence_of(:location) }
        it { is_expected.to validate_presence_of(:status) }
    end

    describe "associations" do
        it { is_expected.to belong_to(:zone).counter_cache(true) }
        it { is_expected.to have_many(:sensor_logs).dependent(:destroy) }
        it { is_expected.to have_one(:latest_log).class_name('SensorLog') }

        it "has many alerts as owner" do
            sensor = create(:sensor)
            alert1 = create(:alert, owner: sensor, zone: sensor.zone)
            alert2 = create(:alert, owner: sensor, zone: sensor.zone)
            expect(sensor.alerts).to include(alert1, alert2)
        end

        it "destroys associated alerts when destroyed" do
            sensor = create(:sensor)
            create(:alert, owner: sensor, zone: sensor.zone)
            expect { sensor.destroy }.to change(Alert, :count).by(-1)
        end
    end

    describe "enums" do
        it do
            is_expected.to define_enum_for(:status)
                .with_values(active: 0, inactive: 1, error: 2)
        end
    end

    describe "scopes" do
        describe ".newest" do
            it "orders sensors by creation date descending" do
                oldest = create(:sensor, created_at: 1.day.ago)
                newest = create(:sensor, created_at: Time.current)
                expect(Sensor.newest).to eq([newest, oldest])
            end
        end
    end

    describe "Ransack configuration" do
        it "returns a whitelist of searchable attributes" do
            expected_attrs = %w[name location status threshold created_at]
            expect(Sensor.ransackable_attributes).to match_array(expected_attrs)
        end

        it "returns a whitelist of searchable associations" do
            expected_assocs = %w[zone]
            expect(Sensor.ransackable_associations).to match_array(expected_assocs)
        end
    end

    describe "constants" do
        it "defines SENSOR_PERMITTED with correct attributes" do
            expected = %i[name location status zone_id threshold sensitivity latitude longitude]
            expect(Sensor::SENSOR_PERMITTED).to match_array(expected)
        end

        it "defines PRELOAD with correct associations" do
            expected = %i[zone latest_log]
            expect(Sensor::PRELOAD).to match_array(expected)
        end
    end
end
