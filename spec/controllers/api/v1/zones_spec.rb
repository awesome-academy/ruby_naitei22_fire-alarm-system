require "rails_helper"

RSpec.describe "Api::V1::Zones", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:supervisor) { create(:user, :supervisor, admin: admin) }
  let!(:zone) { create(:zone, user: supervisor) }

  before do
    allow_any_instance_of(Api::V1::BaseController)
      .to receive(:current_user)
      .and_return(supervisor)
  end

  def json_response
    JSON.parse(response.body)
  end

  describe "GET /api/v1/zones" do
    subject { get "/api/v1/zones", params: params }
    let(:params) { {} }

    it "returns paginated zones" do
      create_list(:zone, 5, user: supervisor)

      subject
      expect(response).to have_http_status(:ok)

      body = json_response
      expect(body["data"]).to be_an(Array)
      expect(body["data"].first).to have_key("id")
      expect(body).to have_key("pagy")
    end

    context "when sort by name" do
      let(:params) { { sort: "name" } }

      it "returns zones sorted by name asc" do
        create(:zone, name: "A Zone", user: supervisor)
        create(:zone, name: "C Zone", user: supervisor)
        create(:zone, name: "B Zone", user: supervisor)

        subject
        names = json_response["data"].map { |z| z["name"] }
        expect(names).to include("A Zone", "B Zone", "C Zone")
        expect(names.first(3)).to eq(["A Zone", "B Zone", "C Zone"])
      end
    end
  end

  describe "GET /api/v1/zones/:id" do
    subject { get "/api/v1/zones/#{zone_id}" }

    context "when zone exists" do
      let(:zone_id) { zone.id }

      it "returns the zone" do
        subject
        expect(response).to have_http_status(:ok)
        expect(json_response["data"]["id"].to_i).to eq(zone.id)
      end
    end

    context "when zone does not exist" do
      let(:zone_id) { -1 }

      it "returns 404" do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/zones" do
    subject { post "/api/v1/zones", params: params }

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
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid params" do
      let(:params) { { zone: { name: "" } } }

      it "returns unprocessable entity" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /api/v1/zones/:id" do
    subject { patch "/api/v1/zones/#{zone.id}", params: params }

    context "with valid params" do
      let(:params) { { zone: { name: "Updated Name" } } }

      it "updates the zone" do
        subject
        expect(response).to have_http_status(:ok)
        expect(zone.reload.name).to eq("Updated Name")
      end
    end

    context "with invalid params" do
      let(:params) { { zone: { name: "" } } }

      it "returns error" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /api/v1/zones/:id" do
    subject { delete "/api/v1/zones/#{zone_to_delete.id}" }
    let!(:zone_to_delete) { create(:zone, user: supervisor) }

    it "deletes the zone" do
      expect { subject }.to change(Zone, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end

    context "when the zone fails to be destroyed" do
      before do
        allow_any_instance_of(Zone).to receive(:destroy).and_return(false)
        delete "/api/v1/zones/#{zone_to_delete.id}"
      end

      it "returns an unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
