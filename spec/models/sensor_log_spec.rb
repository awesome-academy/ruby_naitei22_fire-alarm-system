require "rails_helper"

RSpec.describe SensorLog, type: :model do
    describe "validations" do
        it { is_expected.to validate_presence_of(:sensor_id) }
        it { is_expected.to validate_numericality_of(:temperature).allow_nil }
        it { is_expected.to validate_numericality_of(:humidity).allow_nil }
    end

    describe "associations" do
        it { is_expected.to belong_to(:sensor) }
    end

    describe "scopes" do
        let!(:sensor) { create(:sensor) }
        let!(:log_now) { create(:sensor_log, sensor: sensor, created_at: Time.current, temperature: 30) }
        let!(:log_1_hour_ago) { create(:sensor_log, sensor: sensor, created_at: 1.hour.ago, temperature: 28) }
        let!(:log_25_hours_ago) { create(:sensor_log, sensor: sensor, created_at: 25.hours.ago, temperature: 25) }

        describe ".newest" do
            it "orders by created_at descending" do
                expect(SensorLog.newest.first).to eq(log_now)
            end
        end

        describe ".recent_hours(24)" do
            it "returns logs within the last 24 hours" do
                expect(SensorLog.recent_hours(24)).to contain_exactly(log_now, log_1_hour_ago)
            end
        end

        describe ".with_temperature" do
            it "returns logs that have a temperature" do
                create(:sensor_log, sensor: sensor, temperature: nil)
                expect(SensorLog.with_temperature).to contain_exactly(log_now, log_1_hour_ago, log_25_hours_ago)
            end
        end

        describe ".by_sensor_ids" do
            it "returns logs for the given sensor ids" do
                other_sensor = create(:sensor)
                log_for_other_sensor = create(:sensor_log, sensor: other_sensor)
                expect(SensorLog.by_sensor_ids([other_sensor.id])).to contain_exactly(log_for_other_sensor)
            end
        end

        describe ".created_after" do
            it "returns logs created after a specific time" do
                expect(SensorLog.created_after(2.hours.ago)).to contain_exactly(log_now, log_1_hour_ago)
            end
        end

        describe ".in_time_range" do
            it "returns logs within a specific time range" do
                start_time = 1.5.hours.ago
                end_time = 0.5.hours.ago
                expect(SensorLog.in_time_range(start_time, end_time)).to contain_exactly(log_1_hour_ago)
            end
        end
    end

    describe "constants" do
        it "defines CHART_DATA_COLUMNS correctly" do
            expect(SensorLog::CHART_DATA_COLUMNS).to eq(%w[sensor_id created_at temperature humidity])
        end
    end
end
