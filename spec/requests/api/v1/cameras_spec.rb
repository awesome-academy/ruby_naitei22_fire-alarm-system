require "rails_helper"

RSpec.describe Api::V1::CamerasController, type: :controller do
    let!(:admin_user) { create(:user, :admin) }
    let!(:supervisor_user) { create(:user, :supervisor, admin: admin_user) }
    let!(:zone) { create(:zone, user: supervisor_user) }
    let!(:camera1) { create(:camera, zone: zone, name: "Lobby Camera") }
    let!(:camera2) { create(:camera, zone: zone, name: "Parking Camera") }

    def allow_authentication(user)
        allow(controller).to receive(:authenticate_request!).and_return(true)
        allow(controller).to receive(:authorize_admin!).and_return(true)
        controller.instance_variable_set(:@current_user, user)
    end

    def allow_unauthorized_access
        allow(controller).to receive(:authenticate_request!).and_raise(Api::V1::BaseController::NotAuthenticatedError)
    end

    def allow_forbidden_access(user)
        allow(controller).to receive(:authenticate_request!).and_return(true)
        controller.instance_variable_set(:@current_user, user)
        allow(controller).to receive(:authorize_admin!).and_raise(Api::V1::BaseController::NotAuthorizedError)
    end

    describe "GET #index" do
        context "when authenticated as an admin" do
            before do
                allow_authentication(admin_user)
                get :index, format: :json
            end

            it "returns a successful http status" do
                expect(response).to have_http_status(:ok)
            end

            it "returns a success message" do
                expect(JSON.parse(response.body)["message"]).to eq(I18n.t("api.v1.cameras.index.success"))
            end

            it "returns a list of all cameras" do
                expect(JSON.parse(response.body)["data"].size).to eq(2)
            end
        end

        context "when authenticated as a non-admin" do
            it "returns a forbidden status" do
                allow_forbidden_access(supervisor_user)
                get :index, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end

        context "when not authenticated" do
            it "returns an unauthorized status" do
                allow_unauthorized_access
                get :index, format: :json
                expect(response).to have_http_status(:unauthorized)
            end
        end
    end

    describe "GET #show" do
        before { allow_authentication(admin_user) }

        context "with a valid camera ID" do
            before { get :show, params: { id: camera1.id }, format: :json }
            let(:json_response) { JSON.parse(response.body) }

            it "returns a successful http status" do
                expect(response).to have_http_status(:ok)
            end

            it "returns the correct id" do
                expect(json_response["id"]).to eq(camera1.id)
            end

            it "returns the correct name" do
                expect(json_response["name"]).to eq(camera1.name)
            end

            it "returns the correct url" do
                expect(json_response["url"]).to eq(camera1.url)
            end

            it "returns the correct latitude" do
                expect(json_response["latitude"]).to eq(camera1.latitude)
            end

            it "returns the correct longitude" do
                expect(json_response["longitude"]).to eq(camera1.longitude)
            end

            it "returns the correct status" do
                expect(json_response["status"]).to eq(camera1.status)
            end

            it "returns the correct is_detecting flag" do
                expect(json_response["is_detecting"]).to eq(camera1.is_detecting)
            end

            it "returns the correct last_snapshot_url" do
                expect(json_response["last_snapshot_url"]).to eq(camera1.last_snapshot_url)
            end

            it "returns the correct created_at timestamp" do
                expect(Time.zone.parse(json_response["created_at"])).to be_within(1.second).of(camera1.created_at)
            end

            context "within the associated zone data" do
                it "returns the correct zone id" do
                    expect(json_response["zone"]["id"]).to eq(zone.id)
                end

                it "returns the correct zone name" do
                    expect(json_response["zone"]["name"]).to eq(zone.name)
                end
            end
        end

        context "with an invalid camera ID" do
            it "returns a not found http status" do
                get :show, params: { id: -1 }, format: :json
                expect(response).to have_http_status(:not_found)
            end
        end
    end

    describe "POST #create" do
        before { allow_authentication(admin_user) }

        context "with valid parameters" do
            let(:valid_params) { { camera: { name: "New Cam", url: "rtsp://valid", zone_id: zone.id } } }

            it "creates a new Camera" do
                expect {
                    post :create, params: valid_params, format: :json
                }.to change(Camera, :count).by(1)
            end

            it "returns a created http status" do
                post :create, params: valid_params, format: :json
                expect(response).to have_http_status(:created)
            end

            it "returns a success message" do
                post :create, params: valid_params, format: :json
                json_response = JSON.parse(response.body)
                expect(json_response["message"]).to eq(I18n.t("api.v1.cameras.create.success"))
            end
        end

        context "with invalid parameters" do
            let(:invalid_params) { { camera: { name: "" } } }

            it "does not create a new Camera" do
                expect {
                    post :create, params: invalid_params, format: :json
                }.not_to change(Camera, :count)
            end

            it "returns an unprocessable entity status" do
                post :create, params: invalid_params, format: :json
                expect(response).to have_http_status(:unprocessable_entity)
            end
        end
    end

    describe "PATCH #update" do
        before { allow_authentication(admin_user) }

        context "with valid parameters" do
            let(:new_attributes) { { name: "Updated Name" } }
            before { patch :update, params: { id: camera1.id, camera: new_attributes }, format: :json }

            it "updates the requested camera" do
                camera1.reload
                expect(camera1.name).to eq("Updated Name")
            end

            it "returns an ok http status" do
                expect(response).to have_http_status(:ok)
            end

            it "returns a success message" do
                json_response = JSON.parse(response.body)
                expect(json_response["message"]).to eq(I18n.t("api.v1.cameras.update.success"))
            end
        end

        context "with invalid parameters" do
            it "returns an unprocessable entity status" do
                patch :update, params: { id: camera1.id, camera: { name: "" } }, format: :json
                expect(response).to have_http_status(:unprocessable_entity)
            end
        end
    end

    describe "DELETE #destroy" do
        before { allow_authentication(admin_user) }

        context "when deletion is successful" do
            let!(:camera_to_delete) { create(:camera, zone: zone) }

            it "destroys the requested camera" do
                expect {
                    delete :destroy, params: { id: camera_to_delete.id }
                }.to change(Camera, :count).by(-1)
            end

            it "returns an ok status with a success message" do
                delete :destroy, params: { id: camera1.id }
                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)["message"]).to eq(I18n.t("api.v1.cameras.destroy.success"))
            end
        end

        context "when destruction fails" do
            before do
                allow_any_instance_of(Camera).to receive(:destroy).and_return(false)
            end

            it "returns an unprocessable entity status" do
                delete :destroy, params: { id: camera1.id }
                expect(response).to have_http_status(:unprocessable_entity)
            end
        end
    end

    describe "GET #stats" do
        before do
            allow_authentication(admin_user)
            get :stats, format: :json
        end

        it "returns a successful http status" do
            expect(response).to have_http_status(:ok)
        end

        it "returns the total camera count" do
            expect(JSON.parse(response.body)["total"]).to eq(Camera.count)
        end
    end

    describe "POST #capture_and_upload_snapshot" do
        before { allow_authentication(admin_user) }

        context "when snapshot service succeeds" do
            let(:camera_with_url) { camera1.tap { |c| c.last_snapshot_url = "http://example.com/snap.jpg" } }

            before do
                service_result = Cameras::SnapshotService::Result.new(
                    success?: true, camera: camera_with_url, status_code: :ok
                )
                allow_any_instance_of(Cameras::SnapshotService).to receive(:call).and_return(service_result)
                post :capture_and_upload_snapshot, params: { id: camera1.id }, format: :json
            end

            it "returns a successful http status" do
                expect(response).to have_http_status(:ok)
            end

            it "returns a success message and snapshot url" do
                json_response = JSON.parse(response.body)
                expect(json_response["message"]).to eq(I18n.t("api.v1.cameras.capture_and_upload_snapshot.success"))
                expect(json_response["snapshot_url"]).to eq("http://example.com/snap.jpg")
            end
        end

        context "when snapshot service fails" do
            before do
                error_message = I18n.t("api.v1.cameras.capture_and_upload_snapshot.error")
                service_result = Cameras::SnapshotService::Result.new(
                    success?: false, error: "Service failed", status_code: :internal_server_error
                )
                allow_any_instance_of(Cameras::SnapshotService).to receive(:call).and_return(service_result)
                post :capture_and_upload_snapshot, params: { id: camera1.id }, format: :json
            end

            it "returns an internal server error status" do
                expect(response).to have_http_status(:internal_server_error)
            end

            it "returns an error message" do
                expected_message = I18n.t("api.v1.cameras.capture_and_upload_snapshot.error")
                expect(JSON.parse(response.body)["error"]).to eq("Service failed")
            end
        end
    end
end
