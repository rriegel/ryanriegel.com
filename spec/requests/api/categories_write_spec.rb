require "rails_helper"

RSpec.describe "API::Categories Write Operations", type: :request do
  let(:user) { create(:user, password: "password123", password_confirmation: "password123") }

  def login
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }, as: :json
  end

  def login_and_get_token
    login
    @auth_token = response.parsed_body.dig("data", "token")
  end

  def auth_headers
    { "Authorization" => "Bearer #{@auth_token}" }
  end

  describe "POST /api/v1/categories" do
    let(:valid_params) do
      {
        category: {
          name: "Technology",
          slug: "technology"
        }
      }
    end

    it "creates a category when authenticated" do
      login_and_get_token
      post "/api/v1/categories", params: valid_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["name"]).to eq("Technology")
      expect(response.parsed_body["slug"]).to eq("technology")
    end

    it "returns 401 when not authenticated" do
      post "/api/v1/categories", params: valid_params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/categories/:slug" do
    let!(:category) { create(:category, name: "Old Name", slug: "old-name") }

    it "updates a category when authenticated" do
      login_and_get_token
      patch "/api/v1/categories/old-name",
            params: { category: { name: "New Name" } },
            headers: auth_headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("New Name")
    end

    it "returns 401 when not authenticated" do
      patch "/api/v1/categories/old-name", params: { category: { name: "New" } }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/categories/:slug" do
    let!(:category) { create(:category, name: "To Delete", slug: "to-delete") }

    it "deletes a category when authenticated" do
      login_and_get_token
      delete "/api/v1/categories/to-delete", headers: auth_headers, as: :json

      expect(response).to have_http_status(:no_content)
      expect(Category.find_by(slug: "to-delete")).to be_nil
    end

    it "returns 401 when not authenticated" do
      delete "/api/v1/categories/to-delete", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
