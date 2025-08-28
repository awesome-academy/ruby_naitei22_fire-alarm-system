require "rails_helper"

RSpec.describe Api::V1::CamerasController, type: :controller do
    let!(:admin_user) { create(:user, :admin) }
    let!(:supervisor_user) { create(:user, :supervisor, admin: admin_user) }
    let!(:other_supervisor) { create(:user, :supervisor, admin: admin_user) }

    let!(:supervisor_zone) { create(:zone, user: supervisor_user) }
    let!(:camera_in_zone) { create(:camera, zone: supervisor_zone, name: "Supervisor's Camera 1") }
    let!(:camera2_in_zone) { create(:camera, zone: supervisor_zone, name: "Supervisor's Camera 2") }

    let!(:other_zone) { create(:zone, user: other_supervisor) }
    let!(:camera_in_other_zone) { create(:camera, zone: other_zone, name: "Other Supervisor's Camera") }

    def allow_authentication(user)
        allow(controller).to receive(:authenticate_request!).and_return(true)
        controller.instance_variable_set(:@current_user, user)
    end

    def allow_unauthorized_access
        allow(controller).to receive(:authenticate_request!).and_raise(Api::V1::BaseController::NotAuthenticatedError)
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

            it "returns a list of ALL cameras" do
                expect(JSON.parse(response.body)["data"].size).to eq(3)
            end
        end

        context "when authenticated as a supervisor" do
            before do
                allow_authentication(supervisor_user)
                get :index, format: :json
            end

            it "returns a successful http status" do
                expect(response).to have_http_status(:ok)
            end

            it "returns ONLY the cameras in their zones" do
                json_response = JSON.parse(response.body)
                expect(json_response["data"].size).to eq(2)
                camera_names = json_response["data"].map { |c| c["name"] }
                expect(camera_names).to contain_exactly("Supervisor's Camera 1", "Supervisor's Camera 2")
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
        context "when authenticated as an admin" do
            before { allow_authentication(admin_user) }

            it "can view any camera" do
                get :show, params: { id: camera_in_other_zone.id }, format: :json
                expect(response).to have_http_status(:ok)
            end
        end

        context "when authenticated as a supervisor" do
            before { allow_authentication(supervisor_user) }

            it "can view their own camera" do
                get :show, params: { id: camera_in_zone.id }, format: :json
                expect(response).to have_http_status(:ok)
            end

            it "CANNOT view a camera from another's zone" do
                get :show, params: { id: camera_in_other_zone.id }, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end
    end

    describe "POST #create" do
        let(:valid_params) { { camera: { name: "New Cam", url: "rtsp://valid", zone_id: supervisor_zone.id } } }

        context "when authenticated as an admin" do
            before { allow_authentication(admin_user) }

            it "can create a camera in any zone" do
                admin_params = { camera: { name: "Admin Cam", url: "rtsp://admin", zone_id: other_zone.id } }
                expect {
                    post :create, params: admin_params, format: :json
                }.to change(Camera, :count).by(1)
                expect(response).to have_http_status(:created)
            end
        end

        context "when authenticated as a supervisor" do
            before { allow_authentication(supervisor_user) }

            it "can create a camera in their own zone" do
                expect {
                    post :create, params: valid_params, format: :json
                }.to change(Camera, :count).by(1)
                expect(response).to have_http_status(:created)
            end

            it "CANNOT create a camera in another's zone" do
                invalid_params = { camera: { name: "Invalid Cam", url: "rtsp://invalid", zone_id: other_zone.id } }
                expect {
                    post :create, params: invalid_params, format: :json
                }.not_to change(Camera, :count)
                expect(response).to have_http_status(:forbidden)
            end
        end
    end

    describe "PATCH #update" do
        let(:new_attributes) { { name: "Updated Name" } }

        context "when authenticated as an admin" do
            before { allow_authentication(admin_user) }

            it "can update any camera" do
                patch :update, params: { id: camera_in_other_zone.id, camera: new_attributes }, format: :json
                expect(response).to have_http_status(:ok)
                expect(camera_in_other_zone.reload.name).to eq("Updated Name")
            end
        end

        context "when authenticated as a supervisor" do
            before { allow_authentication(supervisor_user) }

            it "can update their own camera" do
                patch :update, params: { id: camera_in_zone.id, camera: new_attributes }, format: :json
                expect(response).to have_http_status(:ok)
                expect(camera_in_zone.reload.name).to eq("Updated Name")
            end

            it "CANNOT update a camera in another's zone" do
                patch :update, params: { id: camera_in_other_zone.id, camera: new_attributes }, format: :json
                expect(response).to have_http_status(:forbidden)
                expect(camera_in_other_zone.reload.name).not_to eq("Updated Name")
            end
        end
    end

    describe "DELETE #destroy" do
        let!(:camera_to_delete) { create(:camera, zone: supervisor_zone) }

        context "when authenticated as an admin" do
            before { allow_authentication(admin_user) }

            it "destroys the requested camera" do
                expect {
                    delete :destroy, params: { id: camera_to_delete.id }
                }.to change(Camera, :count).by(-1)
                expect(response).to have_http_status(:ok)
            end
        end

        context "when authenticated as a supervisor" do
            before { allow_authentication(supervisor_user) }

            it "CANNOT destroy a camera and returns a forbidden status" do
                delete :destroy, params: { id: camera_to_delete.id }
                expect(response).to have_http_status(:forbidden)
                expect(Camera.exists?(camera_to_delete.id)).to be true
            end
        end
    end

    describe "POST #capture_and_upload_snapshot" do
        context "when authenticated as a supervisor" do
            before { allow_authentication(supervisor_user) }

            let(:service_result) { Cameras::SnapshotService::Result.new(success?: true, camera: camera_in_zone, status_code: :ok) }

            before do
                allow_any_instance_of(Cameras::SnapshotService).to receive(:call).and_return(service_result)
            end

            it "can capture a snapshot for their own camera" do
                post :capture_and_upload_snapshot, params: { id: camera_in_zone.id }, format: :json
                expect(response).to have_http_status(:ok)
            end

            it "CANNOT capture a snapshot for another's camera" do
                post :capture_and_upload_snapshot, params: { id: camera_in_other_zone.id }, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end
    end
end
