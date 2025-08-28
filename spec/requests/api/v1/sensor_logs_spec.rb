require "rails_helper"

RSpec.describe Api::V1::SensorLogsController, type: :controller do
    let!(:admin_user) { create(:user, :admin) }
    let!(:supervisor_user) { create(:user, :supervisor, admin: admin_user) }
    let!(:supervisor_zone) { create(:zone, user: supervisor_user) }
    let!(:sensor_in_zone) { create(:sensor, zone: supervisor_zone) }
    let!(:log_in_zone) { create_list(:sensor_log, 3, sensor: sensor_in_zone) }
    let!(:other_zone) { create(:zone) }
    let!(:sensor_in_other_zone) { create(:sensor, zone: other_zone) }
    let!(:log_in_other_zone) { create(:sensor_log, sensor: sensor_in_other_zone) }

    def allow_authentication(user)
        allow(controller).to receive(:authenticate_request!).and_return(true)
        controller.instance_variable_set(:@current_user, user)
    end

    describe "GET #index" do
        context "when authenticated as a supervisor" do
            it "returns only logs from their sensors" do
                allow_authentication(supervisor_user)
                get :index, format: :json
                expect(response).to have_http_status(:ok)
                json_response = JSON.parse(response.body)
                expect(json_response["data"].size).to eq(3)
            end
        end
    end

    describe "GET #show" do
        context "when a supervisor views a log from another's zone" do
            it "is forbidden" do
                allow_authentication(supervisor_user)
                get :show, params: { id: log_in_other_zone.id }, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end
    end

    describe "DELETE #destroy" do
        context "when a supervisor tries to delete a log" do
            it "is forbidden" do
                allow_authentication(supervisor_user)
                delete :destroy, params: { id: log_in_zone.first.id }, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end

        context "when an admin fails to delete a log" do
            it "returns unprocessable entity" do
                allow_authentication(admin_user)
                allow_any_instance_of(SensorLog).to receive(:destroy).and_return(false)
                delete :destroy, params: { id: log_in_zone.first.id }, format: :json
                expect(response).to have_http_status(:unprocessable_entity)
            end
        end
    end

    describe "GET #stats" do
        context "when a supervisor tries to get stats" do
            it "is forbidden" do
                allow_authentication(supervisor_user)
                get :stats, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end
    end

    describe "GET #chart" do
        context "when authenticated as a supervisor" do
            before { allow_authentication(supervisor_user) }

            it "is successful with valid params" do
                get :chart, params: { sensorIds: sensor_in_zone.id.to_s }, format: :json
                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)).to have_key(sensor_in_zone.id.to_s)
            end

            it "returns bad request if sensorIds is missing" do
                get :chart, format: :json
                expect(response).to have_http_status(:bad_request)
            end

            it "ignores invalid time format and returns a successful status with default data" do
                get :chart, params: { sensorIds: sensor_in_zone.id.to_s, startTime: "invalid-date" }, format: :json
                expect(response).to have_http_status(:ok)
                json_response = JSON.parse(response.body)
                expect(json_response[sensor_in_zone.id.to_s]).not_to be_empty
            end
        end
    end
end
