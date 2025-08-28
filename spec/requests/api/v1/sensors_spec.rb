require "rails_helper"

RSpec.describe Api::V1::SensorsController, type: :controller do
    let!(:admin_user) { create(:user, :admin) }
    let!(:supervisor_user) { create(:user, :supervisor, admin: admin_user) }
    let!(:other_supervisor) { create(:user, :supervisor, admin: admin_user) }
    let!(:supervisor_zone) { create(:zone, user: supervisor_user) }
    let!(:sensor_in_zone) { create(:sensor, zone: supervisor_zone, name: "Supervisor's Sensor") }
    let!(:other_zone) { create(:zone, user: other_supervisor) }
    let!(:sensor_in_other_zone) { create(:sensor, zone: other_zone, name: "Other's Sensor") }

    def allow_authentication(user)
        allow(controller).to receive(:authenticate_request!).and_return(true)
        controller.instance_variable_set(:@current_user, user)
    end

    describe "GET #index" do
        context "when authenticated as a supervisor" do
            it "returns only their own sensors" do
                allow_authentication(supervisor_user)
                get :index, format: :json
                expect(response).to have_http_status(:ok)
                json_response = JSON.parse(response.body)
                expect(json_response["data"].size).to eq(1)
                expect(json_response["data"][0]["name"]).to eq("Supervisor's Sensor")
            end
        end
    end

    describe "GET #show" do
        context "when a supervisor views another's sensor" do
            it "is forbidden" do
                allow_authentication(supervisor_user)
                get :show, params: { id: sensor_in_other_zone.id }, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end
    end

    describe "POST #create" do
        let(:valid_params) { { sensor: { name: "New Sensor", location: "Warehouse", zone_id: supervisor_zone.id } } }

        context "when a supervisor creates a sensor in another's zone" do
            it "is forbidden" do
                allow_authentication(supervisor_user)
                invalid_params = { sensor: { name: "Invalid Sensor", location: "Office", zone_id: other_zone.id } }
                post :create, params: invalid_params, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end

        context "with invalid data but valid permissions" do
            it "returns unprocessable entity" do
                allow_authentication(supervisor_user)
                invalid_data_params = { sensor: { name: "", zone_id: supervisor_zone.id } }
                post :create, params: invalid_data_params, format: :json
                expect(response).to have_http_status(:unprocessable_entity)
            end
        end
    end

    describe "DELETE #destroy" do
        let!(:sensor_to_delete) { create(:sensor, zone: supervisor_zone) }

        context "when authenticated as an admin" do
            it "destroys the sensor" do
                allow_authentication(admin_user)
                expect {
                    delete :destroy, params: { id: sensor_to_delete.id }
                }.to change(Sensor, :count).by(-1)
                expect(response).to have_http_status(:ok)
            end
        end

        context "when authenticated as a supervisor" do
            it "is forbidden" do
                allow_authentication(supervisor_user)
                delete :destroy, params: { id: sensor_to_delete.id }
                expect(response).to have_http_status(:forbidden)
            end
        end

        context "when deletion fails" do
            before do
                allow_authentication(admin_user)
                allow_any_instance_of(Sensor).to receive(:destroy).and_return(false)
            end
            it "returns unprocessable entity" do
                delete :destroy, params: { id: sensor_to_delete.id }
                expect(response).to have_http_status(:unprocessable_entity)
            end
        end
    end

    describe "GET #stats" do
        context "when authenticated as a supervisor" do
            it "is forbidden" do
                allow_authentication(supervisor_user)
                get :stats, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end
    end

    describe "POST #bulk" do
        let(:valid_bulk_params) { { sensors: [{ name: "Bulk 1", location: "A", zone_id: supervisor_zone.id }] } }
        context "when authenticated as a supervisor" do
            it "is forbidden" do
                allow_authentication(supervisor_user)
                post :bulk, params: valid_bulk_params, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end

        context "when an admin performs a bulk insert with an invalid zone" do
            before { allow_authentication(admin_user) }
            let(:invalid_bulk_params) { { sensors: [{ name: "Bulk Invalid", location: "B", zone_id: -99 }] } }
            it "raises an error and returns unprocessable entity" do
                post :bulk, params: invalid_bulk_params, format: :json
                expect(response).to have_http_status(:unprocessable_entity)
            end
        end
    end
end
