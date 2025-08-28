require "rails_helper"

RSpec.describe Api::V1::UsersController, type: :controller do
    let!(:admin_user) { create(:user, :admin) }
    let!(:supervisor_user_1) { create(:user, :supervisor, admin: admin_user) }
    let!(:supervisor_user_2) { create(:user, :supervisor, admin: admin_user) }

    def allow_authentication(user)
        allow(controller).to receive(:authenticate_request!).and_return(true)
        controller.instance_variable_set(:@current_user, user)
    end

    describe "GET #index" do
        context "when authenticated as an admin" do
            it "returns all users" do
                allow_authentication(admin_user)
                get :index, format: :json
                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)["data"].size).to eq(3)
            end
        end

        context "when authenticated as a supervisor" do
            it "is forbidden" do
                allow_authentication(supervisor_user_1)
                get :index, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end
    end

    describe "GET #show" do
        context "when authenticated as a supervisor" do
            before { allow_authentication(supervisor_user_1) }

            it "can view their own profile" do
                get :show, params: { id: supervisor_user_1.id }, format: :json
                expect(response).to have_http_status(:ok)
            end

            it "can view their admin's profile" do
                get :show, params: { id: admin_user.id }, format: :json
                expect(response).to have_http_status(:ok)
            end

            it "cannot view another supervisor's profile" do
                get :show, params: { id: supervisor_user_2.id }, format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end
    end

    describe "PATCH #update" do
        let(:update_params) { { user: { name: "Updated Name" } } }

        context "when authenticated as a supervisor" do
            before { allow_authentication(supervisor_user_1) }

            it "can update their own profile" do
                patch :update, params: { id: supervisor_user_1.id }.merge(update_params), format: :json
                expect(response).to have_http_status(:ok)
                expect(supervisor_user_1.reload.name).to eq("Updated Name")
            end

            it "cannot update another user's profile" do
                patch :update, params: { id: supervisor_user_2.id }.merge(update_params), format: :json
                expect(response).to have_http_status(:forbidden)
            end
        end

        context "when an admin updates a supervisor's profile" do
            it "is successful" do
                allow_authentication(admin_user)
                patch :update, params: { id: supervisor_user_1.id }.merge(update_params), format: :json
                expect(response).to have_http_status(:ok)
                expect(supervisor_user_1.reload.name).to eq("Updated Name")
            end
        end

        context "with invalid data" do
            it "returns unprocessable entity" do
                allow_authentication(supervisor_user_1)
                patch :update, params: { id: supervisor_user_1.id, user: { name: "" } }, format: :json
                expect(response).to have_http_status(:unprocessable_entity)
            end
        end
    end
end
