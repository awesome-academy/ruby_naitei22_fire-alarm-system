require "rails_helper"

RSpec.describe Api::V1::ZonesController, type: :controller do
  let(:admin) { create(:user, :admin) }
  let(:supervisor) { create(:user, :supervisor, admin: admin) }
  let!(:zone) { create(:zone, user: supervisor) }

  before do
    allow(controller).to receive(:current_user).and_return(supervisor)
  end

  def json_response
    JSON.parse(response.body)
  end

  describe "GET #index" do
    subject { get :index, params: params }
    let(:params) { {} }

    before do
      create_list(:zone, 5, user: supervisor)
      subject
    end

    it "returns a successful response" do
      expect(response).to have_http_status(:ok)
    end

    it "returns data as an array" do
      expect(json_response["data"]).to be_an(Array)
    end

    it "returns zone objects with an 'id' key" do
      expect(json_response["data"].first).to have_key("id")
    end

    it "returns pagination information" do
      expect(json_response).to have_key("pagy")
    end

    context "when sort by name" do
      let(:params) { { sort: "name" } }

      it "returns zones sorted by name asc" do
        create(:zone, name: "A Zone", user: supervisor)
        create(:zone, name: "C Zone", user: supervisor)
        create(:zone, name: "B Zone", user: supervisor)

        get :index, params: params
        names = json_response["data"].map { |z| z["name"] }
        expect(names).to include("A Zone", "B Zone", "C Zone")
        expect(names.first(3)).to eq(["A Zone", "B Zone", "C Zone"])
      end
    end
  end

  describe "GET #show" do
    subject { get :show, params: { id: zone_id } }

    context "when zone exists" do
      let(:zone_id) { zone.id }

      before { subject }

      it "returns a successful response" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the zone with correct attributes" do
        data = json_response["data"]
        expect(data["id"].to_i).to eq(zone.id)
        expect(data["name"]).to eq(zone.name)
        expect(data["description"]).to eq(zone.description)
        expect(data["city"]).to eq(zone.city)
      end
    end

    context "when zone does not exist" do
      let(:zone_id) { -1 }

      it "returns a not found status" do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #create" do
    subject { post :create, params: params }

    let(:valid_params) do
      {
        zone: {
          name: "Test Zone",
          description: "Some desc",
          city: "Hà Nội",
          latitude: 21.0,
          longitude: 105.8
        }
      }
    end

    context "with valid params" do
      let(:params) { valid_params }

      it "creates a new zone" do
        expect { subject }.to change(Zone, :count).by(1)
      end

      it "returns a created status" do
        subject
        expect(response).to have_http_status(:created)
      end

      it "creates a zone with correct attributes" do
        subject
        new_zone = Zone.last
        zone_params = valid_params[:zone]
        expect(new_zone.name).to eq(zone_params[:name])
        expect(new_zone.description).to eq(zone_params[:description])
        expect(new_zone.city).to eq(zone_params[:city])
      end
    end

    context "with invalid params" do
      let(:params) { { zone: { name: "" } } }

      it "does not create a new zone" do
        expect { subject }.not_to change(Zone, :count)
      end

      it "returns an unprocessable entity status" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH #update" do
    subject { patch :update, params: params.merge(id: zone.id) }

    context "with valid params" do
      let(:params) { { zone: { name: "Updated Name" } } }

      before { subject }

      it "returns a successful response" do
        expect(response).to have_http_status(:ok)
      end

      it "updates the zone's name" do
        expect(zone.reload.name).to eq("Updated Name")
      end
    end

    context "with invalid params" do
      let(:params) { { zone: { name: "" } } }

      it "returns an unprocessable entity status" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: { id: zone_to_delete.id } }
    let!(:zone_to_delete) { create(:zone, user: supervisor) }

    it "deletes the zone" do
      expect { subject }.to change(Zone, :count).by(-1)
    end

    it "returns a successful response" do
      subject
      expect(response).to have_http_status(:ok)
    end

    context "when the zone fails to be destroyed" do
      before do
        allow_any_instance_of(Zone).to receive(:destroy).and_return(false)
        subject
      end

      it "returns an unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
