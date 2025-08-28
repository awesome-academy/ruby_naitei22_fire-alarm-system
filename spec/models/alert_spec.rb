require "rails_helper"

RSpec.describe Alert, type: :model do
    let(:camera) { create(:camera) }
    let(:zone) { camera.zone }

    describe "validations" do
        subject { build(:alert, owner: camera, zone: zone) }

        it { is_expected.to validate_presence_of(:message) }
        it { is_expected.to validate_presence_of(:owner) }
        it { is_expected.to validate_presence_of(:zone) }

        it "is valid with valid attributes" do
            expect(subject).to be_valid
        end
    end

    describe "associations" do
        it { is_expected.to belong_to(:owner) }
        it { is_expected.to belong_to(:zone) }
        it { is_expected.to belong_to(:user).optional }
        it { is_expected.to have_one_attached(:snapshot) }
    end

    describe "enums" do
        it do
            is_expected.to define_enum_for(:status)
                .with_values(pending: 0, resolved: 1, ignored: 2)
        end
        it do
            is_expected.to define_enum_for(:origin)
                .with_values(sensor_threshold: 0, sensor_error: 1, ml_detection: 2, manual_input: 3)
        end
    end

    describe "scopes" do
        let!(:pending_alert) { create(:alert, owner: camera, zone: zone, status: :pending, created_at: 2.days.ago) }
        let!(:resolved_alert) { create(:alert, owner: camera, zone: zone, status: :resolved, created_at: 1.day.ago) }

        describe ".newest" do
            it "orders alerts by creation date descending" do
                expect(Alert.newest).to eq([resolved_alert, pending_alert])
            end
        end

        describe ".with_status" do
            it "returns alerts with the specified status" do
                expect(Alert.with_status("pending")).to contain_exactly(pending_alert)
            end

            it "returns all alerts if status is nil" do
                expect(Alert.with_status(nil)).to contain_exactly(pending_alert, resolved_alert)
            end

            it "returns no alerts if status is invalid" do
                expect(Alert.with_status("invalid_status")).to be_empty
            end
        end

        describe ".in_date_range" do
            it "returns alerts within the specified date range" do
                start_date = 3.days.ago.to_date.to_s
                end_date = Time.current.to_date.to_s
                expect(Alert.in_date_range(start_date, end_date)).to contain_exactly(pending_alert, resolved_alert)
            end

            it "returns nothing if the range is outside the creation dates" do
                start_date = 4.days.ago.to_date.to_s
                end_date = 3.days.ago.to_date.to_s
                expect(Alert.in_date_range(start_date, end_date)).to be_empty
            end

            it "returns all alerts if end_date is missing" do
                expect(Alert.in_date_range(3.days.ago.to_s, nil)).to contain_exactly(pending_alert, resolved_alert)
            end

            it "returns all alerts if start_date is missing" do
                expect(Alert.in_date_range(nil, Time.current.to_s)).to contain_exactly(pending_alert, resolved_alert)
            end

            it "returns all alerts for invalid date formats" do
                expect(Alert.in_date_range("invalid-date", "2025-01-01")).to contain_exactly(pending_alert, resolved_alert)
            end
        end
    end

    describe "methods" do
        describe "#notification_recipient" do
            it "returns the user associated with the zone" do
                alert = build(:alert, zone: zone)
                expect(alert.notification_recipient).to eq(zone.user)
            end
        end

        describe ".pending_count" do
            it "returns the count of pending alerts" do
                create(:alert, owner: camera, zone: zone, status: :pending)
                create(:alert, owner: camera, zone: zone, status: :resolved)
                expect(Alert.pending_count).to eq(1)
            end
        end
    end

    describe "constants" do
        it "defines ALERT_PERMIT with correct attributes" do
            expected_permit = %i[message origin status via_email owner_id owner_type zone_id]
            expect(Alert::ALERT_PERMIT).to match_array(expected_permit)
        end

        it "defines ALERTS_PRELOAD with correct associations" do
            expected_preload = %i[user zone owner]
            expect(Alert::ALERTS_PRELOAD).to match_array(expected_preload)
        end
    end
end
