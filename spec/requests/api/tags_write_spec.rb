require "rails_helper"

RSpec.describe "API::Tags Write Operations", type: :request do
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

  describe "POST /api/v1/tags" do
    let(:valid_params) do
      {
        tag: {
          name: "Ruby",
          slug: "ruby"
        }
      }
    end

    it "creates a tag when authenticated" do
      login_and_get_token
      post "/api/v1/tags", params: valid_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["name"]).to eq("Ruby")
      expect(response.parsed_body["slug"]).to eq("ruby")
    end

    it "returns 401 when not authenticated" do
      post "/api/v1/tags", params: valid_params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/tags/:slug" do
    let!(:tag) { create(:tag, name: "Old Tag", slug: "old-tag") }

    it "updates a tag when authenticated" do
      login_and_get_token
      patch "/api/v1/tags/old-tag",
            params: { tag: { name: "New Tag" } },
            headers: auth_headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("New Tag")
    end

    it "returns 401 when not authenticated" do
      patch "/api/v1/tags/old-tag", params: { tag: { name: "New" } }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/tags/:slug" do
    let!(:tag) { create(:tag, name: "To Delete", slug: "to-delete") }

    it "deletes a tag when authenticated" do
      login_and_get_token
      delete "/api/v1/tags/to-delete", headers: auth_headers, as: :json

      expect(response).to have_http_status(:no_content)
      expect(Tag.find_by(slug: "to-delete")).to be_nil
    end

    it "returns 401 when not authenticated" do
      delete "/api/v1/tags/to-delete", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
