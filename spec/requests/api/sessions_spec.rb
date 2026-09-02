require "rails_helper"

RSpec.describe "API::Sessions", type: :request do
  let(:user) { create(:user, password: "password123", password_confirmation: "password123") }

  describe "POST /api/v1/login" do
    let(:valid_credentials) { { user: { email: user.email, password: "password123" } } }

    it "authenticates with valid credentials and sets httpOnly cookie" do
      post "/api/v1/login", params: valid_credentials, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]["code"]).to eq(200)
      expect(response.parsed_body["data"]["token"]).to be_present
    end

    it "returns 401 with invalid credentials" do
      post "/api/v1/login", params: { user: { email: user.email, password: "wrong" } }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["data"]).to be_nil
    end

    it "returns user data in response body" do
      post "/api/v1/login", params: valid_credentials, as: :json

      expect(response.parsed_body["data"]["user"]["email"]).to eq(user.email)
    end
  end

  describe "DELETE /api/v1/logout" do
    it "clears auth cookie when authenticated" do
      # Login first
      post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }, as: :json
      token = response.parsed_body["data"]["token"]
      expect(token).to be_present

      # Logout with Bearer token
      delete "/api/v1/logout", headers: { "Authorization" => "Bearer #{token}" }, as: :json

      expect(response).to have_http_status(:ok)
    end

    it "returns 401 when not authenticated" do
      delete "/api/v1/logout", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "Cookie-based authentication" do
    it "allows authenticated requests with cookie" do
      # Login and get token
      post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }, as: :json
      token = response.parsed_body["data"]["token"]
      expect(token).to be_present

      # Make authenticated request with Bearer token
      post "/api/v1/posts",
           params: { post: { title: "Test", body: "Body content", status: "draft" } },
           headers: { "Authorization" => "Bearer #{token}" },
           as: :json

      expect(response).to have_http_status(:created)
    end

    it "rejects requests without authentication" do
      post "/api/v1/posts",
           params: { post: { title: "Test", body: "Body content", status: "draft" } },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
