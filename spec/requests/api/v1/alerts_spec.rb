require "rails_helper"

RSpec.describe Api::V1::AlertsController, type: :controller do
    let!(:admin_user) { create(:user, :admin) }
    let!(:supervisor_user) { create(:user, :supervisor, admin: admin_user) }
    let!(:other_supervisor) { create(:user, :supervisor, admin: admin_user) }

    def allow_authentication(user)
        allow(controller).to receive(:authenticate_request!).and_return(true)
        controller.instance_variable_set(:@current_user, user)
    end

    describe "GET #index" do
        let!(:supervisor_zone) { create(:zone, user: supervisor_user) }
        let!(:camera_in_zone) { create(:camera, zone: supervisor_zone) }
        let!(:alert_in_zone) { create(:alert, owner: camera_in_zone, zone: supervisor_zone, message: "Supervisor's Alert", status: :pending) }

        let!(:other_zone) { create(:zone, user: other_supervisor) }
        let!(:camera_in_other_zone) { create(:camera, zone: other_zone) }
        let!(:alert_in_other_zone) { create(:alert, owner: camera_in_other_zone, zone: other_zone, message: "Other's Alert", status: :pending) }

        context "when authenticated as an admin" do
            it "returns a list of all alerts" do
                allow_authentication(admin_user)
                get :index, format: :json
                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)["data"].size).to eq(2)
            end
        end

        context "when authenticated as a supervisor" do
            it "returns only the alerts in their zones" do
                allow_authentication(supervisor_user)
                get :index, format: :json
                expect(response).to have_http_status(:ok)
                json_response = JSON.parse(response.body)
                expect(json_response["data"].size).to eq(1)
                expect(json_response["data"][0]["message"]).to eq("Supervisor's Alert")
            end
        end

        context "with Ransack search parameters" do
            before { allow_authentication(admin_user) }

            it "filters by status" do
                create(:alert, owner: camera_in_zone, zone: supervisor_zone, status: :resolved)
                get :index, params: { q: { status_eq: 0 } }, format: :json
                json_response = JSON.parse(response.body)
                expect(json_response["data"].size).to eq(2)
                json_response["data"].each { |alert| expect(alert["status"]).to eq("pending") }
            end

            it "handles invalid JSON in q param" do
                get :index, params: { q: "{invalid_json" }, format: :json
                expect(response).to have_http_status(:bad_request)
            end
        end
    end

    describe "GET #stats" do
        before { allow_authentication(admin_user) }

        it "returns the count of pending alerts" do
            Alert.destroy_all
            create_list(:alert, 3, status: :pending, owner: create(:camera), zone: create(:zone))
            create_list(:alert, 2, status: :resolved, owner: create(:camera), zone: create(:zone))

            get :stats, format: :json
            expect(response).to have_http_status(:ok)
            expect(JSON.parse(response.body)["pending"]).to eq(3)
        end
    end

    describe "GET #show" do
        let(:supervisor_zone) { create(:zone, user: supervisor_user) }
        let(:alert_in_zone) { create(:alert, owner: create(:camera, zone: supervisor_zone), zone: supervisor_zone) }
        let(:alert_in_other_zone) { create(:alert, owner: create(:camera), zone: create(:zone)) }

        context "when authenticated as a supervisor" do
            before { allow_authentication(supervisor_user) }

            it "can view their own alert" do
                get :show, params: { id: alert_in_zone.id }, format: :json
                expect(response).to have_http_status(:ok)
            end

            it "cannot view an alert from another's zone" do
                get :show, params: { id: alert_in_other_zone.id }, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end
    end

    describe "POST #create" do
        let(:zone) { create(:zone) }
        let(:camera) { create(:camera, zone: zone) }
        let(:valid_params) { { alert: { message: "Manual Alert", owner_id: camera.id, owner_type: "Camera", zone_id: zone.id } } }

        context "when authenticated as an admin" do
            before { allow_authentication(admin_user) }

            it "can create a new alert" do
                expect {
                    post :create, params: valid_params, format: :json
                }.to change(Alert, :count).by(1)
                expect(response).to have_http_status(:created)
            end

            it "returns unprocessable entity with invalid parameters" do
                post :create, params: { alert: { message: "" } }, format: :json
                expect(response).to have_http_status(:unprocessable_entity)
            end
        end

        context "when authenticated as a supervisor" do
            before { allow_authentication(supervisor_user) }

            it "cannot create a new alert" do
                expect {
                    post :create, params: valid_params, format: :json
                }.not_to change(Alert, :count)
                expect(response).to have_http_status(:forbidden)
            end
        end
    end

    describe "PATCH #update_status" do
        let(:alert_to_update) { create(:alert, owner: create(:camera), zone: create(:zone, user: supervisor_user)) }

        context "when authenticated as a supervisor" do
            before { allow_authentication(supervisor_user) }

            it "can update status of their own alert" do
                patch :update_status, params: { id: alert_to_update.id, status: "resolved" }, format: :json
                expect(response).to have_http_status(:ok)
                expect(alert_to_update.reload.status).to eq("resolved")
            end
        end

        context "when update fails" do
            before do
                allow_authentication(admin_user)
                service_result = Alerts::StatusUpdaterService::Result.new(success?: false, errors: ["Update failed"])
                allow_any_instance_of(Alerts::StatusUpdaterService).to receive(:call).and_return(service_result)
            end

            it "returns an unprocessable entity status" do
                patch :update_status, params: { id: alert_to_update.id, status: "resolved" }, format: :json
                expect(response).to have_http_status(:unprocessable_entity)
                json_response = JSON.parse(response.body)
                expect(json_response["error"]).to eq(["Update failed"])
            end
        end
    end
end
