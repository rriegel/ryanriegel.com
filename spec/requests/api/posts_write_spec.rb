require "rails_helper"

RSpec.describe "API::Posts Write Operations", type: :request do
  let(:user) { create(:user, password: "password123", password_confirmation: "password123") }

  def login
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }, as: :json
  end

  describe "POST /api/v1/posts" do
    let(:valid_params) do
      {
        post: {
          title: "New Post",
          body: "This is the body content",
          status: "draft"
        }
      }
    end

    it "creates a post when authenticated" do
      login
      post "/api/v1/posts", params: valid_params, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["title"]).to eq("New Post")
      expect(response.parsed_body["slug"]).to eq("new-post")
    end

    it "returns 401 when not authenticated" do
      post "/api/v1/posts", params: valid_params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns errors for invalid post" do
      login
      post "/api/v1/posts", params: { post: { title: "", body: "" } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "PATCH /api/v1/posts/:slug" do
    let!(:post_record) { create(:post, title: "Original Title", slug: "original-title") }

    it "updates a post when authenticated" do
      login
      patch "/api/v1/posts/original-title",
            params: { post: { title: "Updated Title" } },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["title"]).to eq("Updated Title")
    end

    it "returns 401 when not authenticated" do
      patch "/api/v1/posts/original-title", params: { post: { title: "Updated" } }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/posts/:slug" do
    let!(:post_record) { create(:post, title: "To Delete", slug: "to-delete") }

    it "deletes a post when authenticated" do
      login
      delete "/api/v1/posts/to-delete", as: :json

      expect(response).to have_http_status(:no_content)
      expect(Post.find_by(slug: "to-delete")).to be_nil
    end

    it "returns 401 when not authenticated" do
      delete "/api/v1/posts/to-delete", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
