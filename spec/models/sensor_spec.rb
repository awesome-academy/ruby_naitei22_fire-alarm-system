require "rails_helper"

RSpec.describe Sensor, type: :model do
  subject { build(:sensor) }

  describe "valid factory" do
    it "has a valid factory" do
      expect(subject).to be_valid
    end
  end

  describe "enums" do
    it "defines correct statuses" do
      expect(described_class.statuses).to eq("active" => 0, "inactive" => 1, "error" => 2)
    end

    shared_examples "a status change" do |initial, transition, predicate|
      subject { create(:sensor, status: initial) }

      it "initial state is #{initial}" do
        expect(subject.status).to eq initial.to_s
      end

      context "when changed to #{transition}" do
        before { subject.public_send("#{transition}!") }

        it "updates status correctly" do
          expect(subject.status).to eq transition.to_s
        end

        it "responds to #{predicate}?" do
          expect(subject.public_send("#{predicate}?")).to be true
        end
      end
    end

    it_behaves_like "a status change", :active, :inactive, :inactive
    it_behaves_like "a status change", :inactive, :error, :error
    it_behaves_like "a status change", :error, :active, :active
  end

  describe "validations" do
    context "when name is blank" do
      subject { build(:sensor, name: nil) }

      it "is invalid" do
        expect(subject).to be_invalid
      end

      it "has name presence error" do
        subject.valid?
        expect(subject.errors[:name]).to include(I18n.t("errors.messages.blank"))
      end
    end

    context "when location is blank" do
      subject { build(:sensor, location: nil) }

      it "is invalid" do
        expect(subject).to be_invalid
      end

      it "has location presence error" do
        subject.valid?
        expect(subject.errors[:location]).to include(I18n.t("errors.messages.blank"))
      end
    end
  end

  describe "associations" do
    let(:zone) { create(:zone) }
    subject { create(:sensor, zone: zone) }

    describe "zone counter_cache" do
      it "increments sensors_count" do
        expect(subject.zone.sensors_count).to eq 1
      end
    end

    context "sensor_logs dependent destroy" do
      subject { create(:sensor) }
      let!(:log) { create(:sensor_log, sensor: subject) }

      it "destroys associated sensor_logs" do
        expect { subject.destroy }.to change(SensorLog, :count).by(-1)
      end
    end

    describe "alerts dependent destroy" do
      let!(:alert) { create(:alert, owner: subject, zone:, user: zone.user) }

      it "destroys associated alert" do
        alert_id = alert.id
        subject.destroy
        expect(Alert.find_by(id: alert_id)).to be_nil
      end
    end

    describe "#latest_log" do
      let!(:old_log) { create(:sensor_log, sensor: subject, created_at: 1.day.ago) }
      let!(:new_log) { create(:sensor_log, sensor: subject, created_at: Time.current) }

      it "returns the latest log" do
        expect(subject.latest_log).to eq new_log
      end
    end
  end

  describe "scopes" do
    let!(:zone1)   { create(:zone) }
    let!(:zone2)   { create(:zone) }
    let!(:sensor1) { create(:sensor, zone: zone1, status: :active,   created_at: 2.days.ago) }
    let!(:sensor2) { create(:sensor, zone: zone1, status: :inactive, created_at: 1.day.ago) }
    let!(:sensor3) { create(:sensor, zone: zone2, status: :error,    created_at: Time.current) }

    describe ".newest" do
      it "orders sensors by newest first" do
        expect(described_class.newest).to eq [sensor3, sensor2, sensor1]
      end
    end

    shared_examples "a filter scope" do |scope_name, param, expected_records|
      context "when param present" do
        subject { described_class.public_send(scope_name, instance_exec(&param)) }

        it "returns correct records" do
          expect(subject).to match_array instance_exec(&expected_records)
        end
      end

      context "when param is nil" do
        subject { described_class.public_send(scope_name, nil) }

        it "returns all records" do
          expect(subject).to match_array(described_class.all)
        end
      end
    end

    describe ".by_zone" do
      it_behaves_like "a filter scope", :by_zone, -> { zone1.id }, -> { [sensor1, sensor2] }
    end

    describe ".by_status" do
      it_behaves_like "a filter scope", :by_status, -> { "active" }, -> { [sensor1] }
    end
  end
end
