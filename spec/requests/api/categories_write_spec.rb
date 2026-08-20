require "rails_helper"

RSpec.describe "API::Categories Write Operations", type: :request do
  let(:user) { create(:user) }
  let(:auth_headers) do
    post "/api/login", params: { user: { email: user.email, password: "password123" } }, as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "POST /api/categories" do
    let(:valid_params) do
      {
        category: {
          name: "Technology",
          slug: "technology"
        }
      }
    end

    it "creates a category when authenticated" do
      post "/api/categories", params: valid_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["name"]).to eq("Technology")
      expect(response.parsed_body["slug"]).to eq("technology")
    end

    it "returns 401 when not authenticated" do
      post "/api/categories", params: valid_params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/categories/:slug" do
    let!(:category) { create(:category, name: "Old Name", slug: "old-name") }

    it "updates a category when authenticated" do
      patch "/api/categories/old-name",
            params: { category: { name: "New Name" } },
            headers: auth_headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("New Name")
    end

    it "returns 401 when not authenticated" do
      patch "/api/categories/old-name", params: { category: { name: "New" } }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/categories/:slug" do
    let!(:category) { create(:category, name: "To Delete", slug: "to-delete") }

    it "deletes a category when authenticated" do
      delete "/api/categories/to-delete", headers: auth_headers, as: :json

      expect(response).to have_http_status(:no_content)
      expect(Category.find_by(slug: "to-delete")).to be_nil
    end

    it "returns 401 when not authenticated" do
      delete "/api/categories/to-delete", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
