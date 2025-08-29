require "rails_helper"

RSpec.describe Zone, type: :model do
  let(:admin) { create(:user, :admin) }
  let(:supervisor) { create(:user, :supervisor, admin: admin) }

  describe "associations" do
    subject(:zone) { create(:zone, user: supervisor) }

    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:sensors).dependent(:destroy) }
    it { is_expected.to have_many(:cameras).dependent(:destroy) }
    it { is_expected.to have_many(:alerts).dependent(:destroy) }

    context "when a zone is destroyed" do
      let!(:zone_to_destroy) { create(:zone, user: supervisor) }

      it "destroys associated sensors" do
        create_list(:sensor, 2, zone: zone_to_destroy)
        expect { zone_to_destroy.destroy }.to change(Sensor, :count).by(-2)
      end

      it "destroys associated cameras" do
        create_list(:camera, 2, zone: zone_to_destroy)
        expect { zone_to_destroy.destroy }.to change(Camera, :count).by(-2)
      end

      it "destroys associated alerts" do
        create_list(:alert, 2, zone: zone_to_destroy)
        expect { zone_to_destroy.destroy }.to change(Alert, :count).by(-2)
      end
    end
  end

  describe "validations" do
    subject { build(:zone, user: supervisor) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }

    it { is_expected.to validate_numericality_of(:latitude).is_greater_than_or_equal_to(-90).is_less_than_or_equal_to(90).allow_nil }
    it { is_expected.to validate_numericality_of(:longitude).is_greater_than_or_equal_to(-180).is_less_than_or_equal_to(180).allow_nil }

    context "with custom location validation" do
      it "is valid with a city but no coordinates" do
        zone = build(:zone, city: "Hanoi", latitude: nil, longitude: nil, user: supervisor)
        expect(zone).to be_valid
      end

      it "is valid with coordinates but a blank city" do
        zone = build(:zone, city: "", latitude: 10.7, longitude: 106.6, user: supervisor)
        expect(zone).to be_valid
      end

      it "is invalid with no city and no latitude" do
        zone = build(:zone, city: "", latitude: nil, longitude: 106.6, user: supervisor)
        expect(zone).not_to be_valid
        expect(zone.errors[:base]).to include("A zone must have a city or both latitude and longitude")
      end
    end
  end

  describe "scopes" do
    let!(:supervisor) { create(:user, :supervisor) }
    let!(:zone_alpha_hanoi) { create(:zone, name: "Alpha", city: "Hà Nội", user: supervisor) }
    let!(:zone_beta_hcm) { create(:zone, name: "Beta", city: "HCM", user: supervisor) }

    it "filters by city" do
      expect(Zone.filter_and_sort({ city: "Hà Nội" })).to contain_exactly(zone_alpha_hanoi)
    end

    it "sorts by name" do
      expect(Zone.filter_and_sort({ sort: "name" })).to eq([zone_alpha_hanoi, zone_beta_hcm])
    end

    describe ".with_location" do
      let!(:zone_with_city) { create(:zone, city: "Đà Nẵng", latitude: nil, longitude: nil, user: supervisor) }
      let!(:zone_with_coords) { create(:zone, city: "", latitude: 10.7, longitude: 106.6, user: supervisor) }

      it "returns zones that have a city or coordinates" do
        expect(Zone.with_location).to contain_exactly(zone_alpha_hanoi, zone_beta_hcm, zone_with_city, zone_with_coords)
      end
    end

    describe ".with_active_sensors" do
      let!(:zone_with_active_sensor) { create(:zone, user: supervisor) }
      let!(:zone_with_inactive_sensor) { create(:zone, user: supervisor) }

      before do
        create(:sensor, zone: zone_with_active_sensor, status: :active)
        create(:sensor, zone: zone_with_inactive_sensor, status: :inactive)
      end

      it "returns only zones with active sensors" do
        expect(Zone.with_active_sensors).to contain_exactly(zone_with_active_sensor)
      end
    end
  end
end
