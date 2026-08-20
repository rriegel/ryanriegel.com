require "rails_helper"

RSpec.describe "API::Tags Write Operations", type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) do
    post "/api/login", params: { user: { email: user.email, password: "password123" } }, as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "POST /api/tags" do
    let(:valid_params) do
      {
        tag: {
          name: "Ruby",
          slug: "ruby"
        }
      }
    end

    it "creates a tag when authenticated" do
      post "/api/tags", params: valid_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["name"]).to eq("Ruby")
      expect(response.parsed_body["slug"]).to eq("ruby")
    end

    it "returns 401 when not authenticated" do
      post "/api/tags", params: valid_params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/tags/:slug" do
    let!(:tag) { create(:tag, name: "Old Tag", slug: "old-tag") }

    it "updates a tag when authenticated" do
      patch "/api/tags/old-tag",
            params: { tag: { name: "New Tag" } },
            headers: auth_headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("New Tag")
    end

    it "returns 401 when not authenticated" do
      patch "/api/tags/old-tag", params: { tag: { name: "New" } }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/tags/:slug" do
    let!(:tag) { create(:tag, name: "To Delete", slug: "to-delete") }

    it "deletes a tag when authenticated" do
      delete "/api/tags/to-delete", headers: auth_headers, as: :json

      expect(response).to have_http_status(:no_content)
      expect(Tag.find_by(slug: "to-delete")).to be_nil
    end

    it "returns 401 when not authenticated" do
      delete "/api/tags/to-delete", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
