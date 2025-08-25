require "rails_helper"

RSpec.describe Api::V1::SensorsController, type: :controller do
  let!(:admin_user) { create(:user, :admin) }
  let!(:supervisor_user) { create(:user, :supervisor, admin: admin_user) }
  let!(:zone) { create(:zone, user: supervisor_user) }
  let!(:sensor) { create(:sensor, zone: zone) }

  describe "GET #show" do
    before { login_as(supervisor_user) }

    context "when sensor exists" do
      it "returns http status ok" do
        get :show, params: { id: sensor.id }
        expect(response).to have_http_status(:ok)
      end

      %i[id name location status threshold sensitivity zone_id].each do |field|
        it "returns correct #{field}" do
          get :show, params: { id: sensor.id }
          expect(JSON.parse(response.body)[field.to_s]).to eq(sensor.send(field))
        end
      end

      it "returns correct latest_log" do
        get :show, params: { id: sensor.id }
        expected_log = sensor.latest_log.present? ? {
          "temperature" => sensor.latest_log.temperature,
          "humidity" => sensor.latest_log.humidity,
          "created_at" => sensor.latest_log.created_at.as_json
        } : nil
        expect(JSON.parse(response.body)["latest_log"]).to eq(expected_log)
      end
    end

    context "when sensor does not exist" do
      it "returns http status not_found" do
        get :show, params: { id: 0 }
        expect(response).to have_http_status(:not_found)
      end

      it "returns not_found error message" do
        get :show, params: { id: 0 }
        expect(JSON.parse(response.body)["error"]).to eq(
          I18n.t("api.v1.sensors.sensor_not_found")
        )
      end
    end
  end

  describe "POST #create" do
    before { login_as(admin_user) }

    let(:valid_params) do
      {
        sensor: {
          name: "New Sensor",
          location: "Room 101",
          status: "active",
          zone_id: zone.id,
          threshold: 50,
          sensitivity: 5,
          latitude: 10.0,
          longitude: 20.0
        }
      }
    end

    let(:invalid_params) { { sensor: { name: "", location: "" } } }

    context "when valid" do
      it "creates a new sensor" do
        expect { post :create, params: valid_params }.to change(Sensor, :count).by(1)
      end

      context "with created sensor (check value match param)" do
        before { post :create, params: valid_params }
        let(:json) { JSON.parse(response.body) }

        %i[name location status zone_id threshold sensitivity latitude longitude].each do |field|
          it "sets #{field} correctly" do
            expect(json["sensor"][field.to_s]).to eq(valid_params[:sensor][field])
          end
        end
      end

      it "returns http status created" do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it "returns success message" do
        post :create, params: valid_params
        expect(JSON.parse(response.body)["message"]).to eq(I18n.t("api.v1.sensors.create.success"))
      end
    end

    context "when invalid" do
      it "returns http status unprocessable_entity" do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error message for name" do
        post :create, params: invalid_params
        json = JSON.parse(response.body)
        expect(json["error"]).to include("#{I18n.t("activerecord.attributes.sensor.name")} #{I18n.t("errors.messages.blank")}")
      end

      it "returns error message for location" do
        post :create, params: invalid_params
        json = JSON.parse(response.body)
        expect(json["error"]).to include("#{I18n.t("activerecord.attributes.sensor.location")} #{I18n.t("errors.messages.blank")}")
      end
    end
  end

  describe "PATCH #update" do
    before { login_as(admin_user) }

    let(:valid_params) do
      {
        id: sensor.id,
        sensor: {
          name: "Updated Sensor",
          location: "Updated Room",
          status: "inactive",
          threshold: 75,
          zone_id: zone.id,
          latitude: 12.345678,
          longitude: 98.765432
        }
      }
    end

    let(:invalid_params) { { id: sensor.id, sensor: { name: "", location: "" } } }

    context "when valid" do
      context "with updated sensor (check value match param)" do
        before { patch :update, params: valid_params }
        let(:json) { JSON.parse(response.body) }

        %i[name location status threshold zone_id latitude longitude].each do |field|
          it "updates #{field} correctly" do
            expect(json["sensor"][field.to_s]).to eq(valid_params[:sensor][field])
          end
        end
      end

      it "returns http status ok" do
        patch :update, params: valid_params
        expect(response).to have_http_status(:ok)
      end

      it "returns success message" do
        patch :update, params: valid_params
        json = JSON.parse(response.body)
        expect(json["message"]).to eq(I18n.t("api.v1.sensors.update.success"))
      end
    end

    context "when invalid" do
      it "returns http status unprocessable_entity when name is blank" do
        patch :update, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error message when name is blank" do
        patch :update, params: invalid_params
        json = JSON.parse(response.body)
        expect(json["error"]).to include("#{I18n.t("activerecord.attributes.sensor.name")} #{I18n.t("errors.messages.blank")}")
      end

      it "returns http status unprocessable_entity when location is blank" do
        patch :update, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error message when location is blank" do
        patch :update, params: invalid_params
        json = JSON.parse(response.body)
        expect(json["error"]).to include("#{I18n.t("activerecord.attributes.sensor.location")} #{I18n.t("errors.messages.blank")}")
      end
    end
    context "when sensor does not exist" do
      it "returns http status not_found" do
        patch :update, params: { id: 0, sensor: { name: "X" } }
        expect(response).to have_http_status(:not_found)
      end

      it "returns not_found error message" do
        patch :update, params: { id: 0, sensor: { name: "X" } }
        expect(JSON.parse(response.body)["error"]).to eq(
          I18n.t("api.v1.sensors.sensor_not_found")
        )
      end
    end
  end

  describe "DELETE #destroy" do
    context "as admin" do
      before { login_as(admin_user) }

      it "destroys the sensor" do
        expect { delete :destroy, params: { id: sensor.id } }.to change(Sensor, :count).by(-1)
      end

      it "returns http status ok" do
        delete :destroy, params: { id: sensor.id }
        expect(response).to have_http_status(:ok)
      end

      it "returns success message" do
        delete :destroy, params: { id: sensor.id }
        json = JSON.parse(response.body)
        expect(json["message"]).to eq(I18n.t("api.v1.sensors.destroy.success"))
      end
    end

    context "as supervisor" do
      before { login_as(supervisor_user) }

      it "returns forbidden status" do
        delete :destroy, params: { id: sensor.id }
        expect(response).to have_http_status(:forbidden)
      end

      it "returns correct i18n error message" do
        delete :destroy, params: { id: sensor.id }
        json = JSON.parse(response.body)
        expect(json["error"]).to eq(I18n.t("api.v1.base_controller.errors.admins_only"))
      end
    end

    context "when sensor does not exist" do
      before { login_as(admin_user) }

      it "returns http status not_found" do
        delete :destroy, params: { id: 0 }
        expect(response).to have_http_status(:not_found)
      end

      it "returns not_found error message" do
        delete :destroy, params: { id: 0 }
        expect(JSON.parse(response.body)["error"]).to eq(
          I18n.t("api.v1.sensors.sensor_not_found")
        )
      end
    end

    context "when destroy fails" do
      before do
        login_as(admin_user)
        allow_any_instance_of(Sensor).to receive(:destroy).and_return(false)
      end

      it "returns unprocessable_entity status" do
        delete :destroy, params: { id: sensor.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns i18n error message" do
        delete :destroy, params: { id: sensor.id }
        json = JSON.parse(response.body)
        expect(json["errors"]).to eq(I18n.t("api.v1.sensors.destroy.failed"))
      end
    end
  end

  describe "GET #index" do
    before { login_as(admin_user)}

    it "returns http status ok" do
      get :index, as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns correct number of sensors" do
      get :index, as: :json
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(Sensor.count)
    end

    it "returns success message" do
      get :index, as: :json
      json = JSON.parse(response.body)
      expect(json["message"]).to eq(I18n.t("api.v1.sensors.index.success"))
    end
  end

  describe "POST #bulk" do
    before { login_as(admin_user) }
    let!(:zone1) { create(:zone, user: supervisor_user) }
    let!(:zone2) { create(:zone, user: supervisor_user) }

    context "when valid" do
      let(:valid_bulk_params) do
        {
          sensors: [
            { name: "Bulk 1", location: "L1", status: :active, zone_id: zone1.id, threshold: 50, sensitivity: 5, latitude: 10.0, longitude: 20.0 },
            { name: "Bulk 2", location: "L2", status: :inactive, zone_id: zone2.id, threshold: 60, sensitivity: 3, latitude: 12.0, longitude: 22.0 }
          ]
        }
      end

      it "creates multiple sensors" do
        expect { post :bulk, params: valid_bulk_params ,as: :json}.to change(Sensor, :count).by(2)
      end

      it "returns http status created" do
        post :bulk, params: valid_bulk_params,as: :json
        expect(response).to have_http_status(:created)
      end

      it "returns success message with count" do
        post :bulk, params: valid_bulk_params,as: :json
        json = JSON.parse(response.body)
        expect(json["message"]).to eq(I18n.t("api.v1.sensors.bulk.success", count: 2))
      end
    end

    context "when invalid" do
      let(:invalid_bulk_params) do
        { sensors: [{ name: "Bulk 3", location: "L3", status: "active", zone_id: 9999 }] }
      end

      it "returns http status unprocessable_entity" do
        post :bulk, params: invalid_bulk_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error message" do
        post :bulk, params: invalid_bulk_params
        json = JSON.parse(response.body)
        expect(json["message"]).to eq(I18n.t("api.v1.sensors.bulk.error"))
      end
    end
  end

  describe "GET #stats" do
    before { login_as(supervisor_user) }

    let(:stats) { Sensors::SensorService.new.get_stats }

    it "returns http status ok" do
      get :stats
      expect(response).to have_http_status(:ok)
    end

    it "returns stats keys" do
      get :stats
      json = JSON.parse(response.body)
      expect(json.keys).to include("active", "inactive", "error", "total")
    end

    %w[active inactive error total].each do |key|
      it "returns correct count for #{key}" do
        get :stats
        json = JSON.parse(response.body)
        expect(json[key]).to eq(stats[key.to_sym])
      end
    end
  end
end
