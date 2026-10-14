require "rails_helper"

RSpec.describe "API::Posts Write Operations", type: :request do
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
      login_and_get_token
      post "/api/v1/posts", params: valid_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["title"]).to eq("New Post")
      expect(response.parsed_body["slug"]).to eq("new-post")
    end

    it "returns 401 when not authenticated" do
      post "/api/v1/posts", params: valid_params, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns errors for invalid post" do
      login_and_get_token
      post "/api/v1/posts", params: { post: { title: "", body: "" } }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "cover image via signed_id" do
    # Content_type is what the model validates; byte content is irrelevant here.
    let(:cover_blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("cover-bytes"),
        filename: "cover.png",
        content_type: "image/png"
      )
    end

    let(:cover_post_params) do
      {
        post: {
          title: "Covered Post",
          body: "<p>with cover</p>",
          status: "draft"
        }
      }
    end
    let!(:existing_post) { create(:post, title: "Existing Title", slug: "existing-title") }

    it "creates a post with a cover image (regression: UnknownAttributeError 500)" do
      login_and_get_token
      post "/api/v1/posts",
           params: { post: cover_post_params[:post].merge(cover_image_signed_id: cover_blob.signed_id) },
           headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      record = Post.find_by!(slug: response.parsed_body["slug"])
      expect(record.cover_image).to be_attached
      expect(response.parsed_body["cover_image"]).to be_present
    end

    it "attaches a replacement cover on update" do
      login_and_get_token
      patch "/api/v1/posts/existing-title",
            params: { post: { cover_image_signed_id: cover_blob.signed_id } },
            headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(existing_post.reload.cover_image).to be_attached
      expect(response.parsed_body["cover_image"]).to be_present
    end

    it "saves without a cover when the signed_id is invalid" do
      login_and_get_token
      post "/api/v1/posts",
           params: { post: cover_post_params[:post].merge(cover_image_signed_id: "garbage-id") },
           headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(Post.find_by!(slug: response.parsed_body["slug"]).cover_image).not_to be_attached
    end

    # Covers the production/CDN branch of servable_blob_url (the dev branch
    # is exercised by every request above that returns a cover_image).
    it "uses ASSET_HOST for the cover image URL in production" do
      controller = Api::V1::PostsController.new
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ASSET_HOST").and_return("cdn.example.com")

      url = controller.send(:servable_blob_url, cover_blob)

      expect(url).to start_with("http://cdn.example.com/rails/active_storage/blobs/redirect/")
      expect(url).to include(cover_blob.signed_id)
      expect(url).to end_with("/cover.png")
    end
  end

  describe "PATCH /api/v1/posts/:slug" do
    let!(:post_record) { create(:post, title: "Original Title", slug: "original-title") }

    it "updates a post when authenticated" do
      login_and_get_token
      patch "/api/v1/posts/original-title",
            params: { post: { title: "Updated Title" } },
            headers: auth_headers,
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["title"]).to eq("Updated Title")
    end

    it "returns 401 when not authenticated" do
      patch "/api/v1/posts/original-title", params: { post: { title: "Updated" } }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "optimistic locking (two-tab conflict)" do
    # Regression: :lock_version was not permitted, so client-sent stale
    # versions were silently discarded and concurrent edits never conflicted.
    it "409s when a second tab saves against a stale lock_version" do
      login_and_get_token
      post "/api/v1/posts",
        params: { post: { title: "Two Tab Spec", slug: "two-tab-spec", body: "<p>v0</p>",
                          status: "draft", tag_ids: [] } },
        headers: auth_headers, as: :json
      slug = response.parsed_body["slug"]
      stale = response.parsed_body["lock_version"]

      # tab A saves first
      patch "/api/v1/posts/#{slug}",
        params: { post: { title: "Two Tab Spec A", lock_version: stale } },
        headers: auth_headers, as: :json
      expect(response).to have_http_status(:ok)

      # tab B saves without refreshing — must conflict
      patch "/api/v1/posts/#{slug}",
        params: { post: { title: "Two Tab Spec B", lock_version: stale } },
        headers: auth_headers, as: :json
      expect(response).to have_http_status(:conflict)

      delete "/api/v1/posts/#{slug}", headers: auth_headers, as: :json
    end

    it "saves cleanly when the lock_version is current" do
      login_and_get_token
      post "/api/v1/posts",
        params: { post: { title: "Fresh Save Spec", slug: "fresh-save-spec", body: "<p>v0</p>",
                          status: "draft", tag_ids: [] } },
        headers: auth_headers, as: :json
      slug = response.parsed_body["slug"]
      current = response.parsed_body["lock_version"]

      patch "/api/v1/posts/#{slug}",
        params: { post: { body: "<p>v1</p>", lock_version: current } },
        headers: auth_headers, as: :json
      expect(response).to have_http_status(:ok)

      delete "/api/v1/posts/#{slug}", headers: auth_headers, as: :json
    end
  end

  describe "slug handling" do
    # Regression: :slug was missing from post_params, so custom slugs were
    # silently discarded and regenerated from the title.
    it "honors a custom slug on create" do
      login_and_get_token
      post "/api/v1/posts",
        params: { post: { title: "Slug Honor Probe", slug: "my-custom-slug", body: "<p>x</p>",
                          status: "draft", tag_ids: [] } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["slug"]).to eq("my-custom-slug")
    end

    it "auto-generates a slug when none is provided" do
      login_and_get_token
      post "/api/v1/posts",
        params: { post: { title: "Auto Slug Still Works", body: "<p>x</p>", status: "draft", tag_ids: [] } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["slug"]).to eq("auto-slug-still-works")
    end
  end

  describe "excerpt persistence" do
    # Regression: :excerpt was missing from post_params, so the admin form's
    # excerpt was silently dropped by strong params and never rendered.
    it "persists the excerpt and exposes it on index and show" do
      login_and_get_token
      post "/api/v1/posts",
        params: { post: { title: "Excerpted Post", slug: "excerpted-post", body: "<p>b</p>",
                          excerpt: "Card summary text", status: "published", tag_ids: [] } },
        headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["excerpt"]).to eq("Card summary text")

      get "/api/v1/posts"
      card = response.parsed_body["data"].find { |p| p["slug"] == "excerpted-post" }
      expect(card["excerpt"]).to eq("Card summary text")

      get "/api/v1/posts/excerpted-post"
      expect(response.parsed_body["excerpt"]).to eq("Card summary text")
    end
  end

  describe "GET /api/v1/posts/:slug draft visibility" do
    let!(:draft_post) { create(:post, title: "Hidden Draft", slug: "hidden-draft", status: "draft") }

    it "returns a draft to an authenticated user" do
      login_and_get_token
      get "/api/v1/posts/hidden-draft", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["title"]).to eq("Hidden Draft")
    end

    it "returns 404 for a draft to an anonymous user (no existence leak)" do
      get "/api/v1/posts/hidden-draft"

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a nonexistent slug even when authenticated" do
      login_and_get_token
      get "/api/v1/posts/no-such-post", headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/posts/:slug" do
    let!(:post_record) { create(:post, title: "To Delete", slug: "to-delete") }

    it "deletes a post when authenticated" do
      login_and_get_token
      delete "/api/v1/posts/to-delete", headers: auth_headers, as: :json

      expect(response).to have_http_status(:no_content)
      expect(Post.find_by(slug: "to-delete")).to be_nil
    end

    it "returns 401 when not authenticated" do
      delete "/api/v1/posts/to-delete", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
