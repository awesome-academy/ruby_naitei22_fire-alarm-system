require "rails_helper"

RSpec.describe Api::V1::ZonesController, type: :controller do
    let!(:admin_user) { create(:user, :admin) }
    let!(:supervisor_user) { create(:user, :supervisor, admin: admin_user) }
    let!(:other_supervisor) { create(:user, :supervisor, admin: admin_user) }
    let!(:supervisor_zone) { create(:zone, user: supervisor_user, name: "Supervisor's Zone") }
    let!(:other_zone) { create(:zone, user: other_supervisor, name: "Other's Zone") }

    def allow_authentication(user)
        allow(controller).to receive(:authenticate_request!).and_return(true)
        controller.instance_variable_set(:@current_user, user)
    end

    describe "GET #index" do
        context "when authenticated as an admin" do
            it "returns all zones" do
                allow_authentication(admin_user)
                get :index, format: :json
                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)["data"].size).to eq(2)
            end
        end

        context "when authenticated as a supervisor" do
            it "returns only their own zones" do
                allow_authentication(supervisor_user)
                get :index, format: :json
                expect(response).to have_http_status(:ok)
                json_response = JSON.parse(response.body)
                expect(json_response["data"].size).to eq(1)
                expect(json_response["data"][0]["name"]).to eq("Supervisor's Zone")
            end
        end
    end

    describe "GET #show" do
        context "when a supervisor views their own zone" do
            it "is successful" do
                allow_authentication(supervisor_user)
                get :show, params: { id: supervisor_zone.id }, format: :json
                expect(response).to have_http_status(:ok)
            end
        end

        context "when a supervisor views another's zone" do
            it "is forbidden" do
                allow_authentication(supervisor_user)
                get :show, params: { id: other_zone.id }, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end
    end

    describe "POST #create" do
        let(:valid_params) { { zone: { name: "New Zone", city: "HCMC" } } }

        context "when a supervisor creates a zone" do
            before { allow_authentication(supervisor_user) }

            it "creates a zone and assigns it to themself" do
                expect {
                    post :create, params: valid_params, format: :json
                }.to change(supervisor_user.zones, :count).by(1)
                expect(response).to have_http_status(:created)
            end
        end

        context "when an admin creates a zone for a supervisor" do
            before { allow_authentication(admin_user) }
            let(:admin_params) { { zone: { name: "Admin Assigned Zone", user_id: other_supervisor.id } } }

            it "creates a zone for the specified supervisor" do
                expect {
                    post :create, params: admin_params, format: :json
                }.to change(other_supervisor.zones, :count).by(1)
                expect(response).to have_http_status(:created)
            end
        end

        context "with invalid data" do
            before { allow_authentication(admin_user) }
            it "returns unprocessable entity" do
                post :create, params: { zone: { name: "" } }, format: :json
                expect(response).to have_http_status(:unprocessable_entity)
            end
        end
    end

    describe "PATCH #update" do
        let(:update_params) { { zone: { name: "Updated Zone Name" } } }

        context "when a supervisor updates their own zone" do
            it "is successful" do
                allow_authentication(supervisor_user)
                patch :update, params: { id: supervisor_zone.id }.merge(update_params), format: :json
                expect(response).to have_http_status(:ok)
                expect(supervisor_zone.reload.name).to eq("Updated Zone Name")
            end
        end

        context "when a supervisor updates another's zone" do
            it "is forbidden" do
                allow_authentication(supervisor_user)
                patch :update, params: { id: other_zone.id }.merge(update_params), format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end

        context "with invalid data" do
            before { allow_authentication(supervisor_user) }
            it "returns unprocessable entity" do
                patch :update, params: { id: supervisor_zone.id, zone: { name: "" } }, format: :json
                expect(response).to have_http_status(:unprocessable_entity)
            end
        end
    end

    describe "DELETE #destroy" do
        let!(:zone_to_delete) { create(:zone, user: supervisor_user) }

        context "when a supervisor deletes their own zone" do
            it "is successful" do
                allow_authentication(supervisor_user)
                expect {
                    delete :destroy, params: { id: zone_to_delete.id }, format: :json
                }.to change(Zone, :count).by(-1)
                expect(response).to have_http_status(:ok)
            end
        end

        context "when a supervisor deletes another's zone" do
            it "is forbidden" do
                allow_authentication(supervisor_user)
                expect {
                    delete :destroy, params: { id: other_zone.id }, format: :json
                }.not_to change(Zone, :count)
                expect(response).to have_http_status(:forbidden)
            end
        end

        context "when deletion fails" do
            before do
                allow_authentication(supervisor_user)
                allow_any_instance_of(Zone).to receive(:destroy).and_return(false)
            end

            it "returns unprocessable entity" do
                delete :destroy, params: { id: supervisor_zone.id }, format: :json
                expect(response).to have_http_status(:unprocessable_entity)
            end
        end
    end
end
