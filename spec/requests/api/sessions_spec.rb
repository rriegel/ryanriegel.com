require "rails_helper"

RSpec.describe "API::Sessions", type: :request do
  let(:user) { create(:user, password: "password123", password_confirmation: "password123") }

  describe "POST /api/v1/login" do
    let(:valid_credentials) { { user: { email: user.email, password: "password123" } } }

    it "authenticates with valid credentials and sets httpOnly cookie" do
      post "/api/v1/login", params: valid_credentials, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]["code"]).to eq(200)
      expect(response.cookies["auth_token"]).to be_present
    end

    it "returns 401 with invalid credentials" do
      post "/api/v1/login", params: { user: { email: user.email, password: "wrong" } }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.cookies["auth_token"]).to be_nil
    end

    it "returns user data in response body" do
      post "/api/v1/login", params: valid_credentials, as: :json

      expect(response.parsed_body["data"]["user"]["email"]).to eq(user.email)
    end
  end

  describe "DELETE /api/v1/logout" do
    it "clears auth cookie when authenticated" do
      # Login first - cookie is automatically persisted in test session
      post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }, as: :json
      expect(response.cookies["auth_token"]).to be_present

      # Logout - cookie is automatically included
      delete "/api/v1/logout", as: :json

      expect(response).to have_http_status(:ok)
    end

    it "returns 401 when not authenticated" do
      delete "/api/v1/logout", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "Cookie-based authentication" do
    it "allows authenticated requests with cookie" do
      # Login - cookie is automatically persisted in test session
      post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }, as: :json
      expect(response.cookies["auth_token"]).to be_present

      # Make authenticated request - cookie is automatically included
      post "/api/v1/posts",
           params: { post: { title: "Test", body: "Body content", status: "draft" } },
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
