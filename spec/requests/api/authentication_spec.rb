require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:user) { create(:user, password: "password123", password_confirmation: "password123") }

  describe "POST /api/v1/register" do
    let(:valid_params) do
      {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    it "creates a new user and sets auth cookie" do
      post "/api/v1/register", params: valid_params, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.cookies["auth_token"]).to be_present
      expect(response.parsed_body["data"]["user"]["email"]).to eq("newuser@example.com")
    end

    it "returns errors for invalid registration" do
      post "/api/v1/register", params: { user: { email: "", password: "x", password_confirmation: "y" } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["status"]["code"]).to eq(422)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "POST /api/v1/login" do
    before { user }

    it "sets auth cookie for valid credentials" do
      post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.cookies["auth_token"]).to be_present
      expect(response.parsed_body["data"]["user"]["email"]).to eq(user.email)
    end

    it "returns 401 for invalid credentials" do
      post "/api/v1/login", params: { user: { email: user.email, password: "wrong" } }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["status"]["code"]).to eq(401)
    end
  end

  describe "DELETE /api/v1/logout" do
    before { user }

    it "logs out successfully" do
      post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }, as: :json
      delete "/api/v1/logout", as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]["message"]).to eq("Logged out successfully.")
    end
  end
end
