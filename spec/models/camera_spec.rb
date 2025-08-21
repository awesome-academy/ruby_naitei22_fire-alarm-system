require "rails_helper"

RSpec.describe Camera, type: :model do
  let(:zone) { create(:zone) }
  let(:valid_attributes) { { name: "Test Cam", url: "rtsp://test.stream", zone: zone } }

  describe "validations" do
    subject { build(:camera, zone: zone) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:zone_id) }

    context "when name is not unique within the same zone" do
      before { create(:camera, name: "Unique Cam", zone: zone) }
      subject { build(:camera, name: "Unique Cam", zone: zone) }

      it "is not valid" do
        expect(subject).not_to be_valid
      end

      it "adds a uniqueness error message to the name attribute" do
        subject.valid?
        expect(subject.errors[:name]).to include(I18n.t("errors.messages.taken"))
      end
    end

    it "allows same name in different zones" do
      zone2 = create(:zone)
      create(:camera, name: "Lobby Cam", zone: zone)
      new_camera_in_zone2 = build(:camera, name: "Lobby Cam", zone: zone2)
      expect(new_camera_in_zone2).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:zone).counter_cache(true) }
    it { is_expected.to have_many(:alerts) }

    it "destroys associated alerts when destroyed" do
      camera = create(:camera)
      create(:alert, owner: camera, zone: camera.zone)
      expect { camera.destroy }.to change(Alert, :count).by(-1)
    end
  end

  describe "enums" do
    it do
      is_expected.to define_enum_for(:status)
        .with_values(online: 0, offline: 1, recording: 2, error: 3)
    end
  end

  describe "callbacks" do
    context "after_initialize" do
      it "sets default status to :online for a new record" do
        camera = Camera.new
        expect(camera).to be_online
      end

      it "does not override specified status on a new record" do
        camera = Camera.new(status: :error)
        expect(camera).to be_error
      end

      it "does not change status for a persisted record" do
        camera = create(:camera, status: :offline)
        camera.reload
        expect(camera).to be_offline
      end
    end
  end

  describe "scopes" do
    describe ".newest" do
      it "orders cameras by creation date descending" do
        oldest_cam = create(:camera, created_at: 1.day.ago)
        newest_cam = create(:camera, created_at: Time.current)
        expect(Camera.newest).to eq([newest_cam, oldest_cam])
      end
    end

    describe ".online_and_detecting" do
      let!(:online_detecting_cam) { create(:camera, status: :online, is_detecting: true) }
      let!(:offline_detecting_cam) { create(:camera, status: :offline, is_detecting: true) }
      let!(:online_not_detecting_cam) { create(:camera, status: :online, is_detecting: false) }

      it "includes online and detecting cameras" do
        expect(Camera.online_and_detecting).to include(online_detecting_cam)
      end

      it "excludes offline cameras" do
        expect(Camera.online_and_detecting).not_to include(offline_detecting_cam)
      end

      it "excludes non-detecting cameras" do
        expect(Camera.online_and_detecting).not_to include(online_not_detecting_cam)
      end
    end
  end

  describe "constants" do
    it "defines CAMERA_PERMIT with correct attributes" do
      expected_permit = %i[name url zone_id latitude longitude status is_detecting]
      expect(Camera::CAMERA_PERMIT).to match_array(expected_permit)
    end

    it "defines VALID_STATUSES with correct values" do
      expected_statuses = %w[online offline recording error]
      expect(Camera::VALID_STATUSES).to match_array(expected_statuses)
    end
  end
end
