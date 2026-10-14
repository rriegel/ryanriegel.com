require "rails_helper"

RSpec.describe "Api::Posts", type: :request do
  let!(:category) { create(:category, name: "Technology") }
  let!(:tag1) { create(:tag, name: "Ruby") }
  let!(:tag2) { create(:tag, name: "Rails") }
  let!(:published_post) do
    create(:post, :published, title: "Published Post", category: category, tags: [ tag1, tag2 ])
  end
  let!(:draft_post) { create(:post, :draft, title: "Draft Post") }

  describe "GET /api/v1/posts" do
    it "returns only published posts" do
      get "/api/v1/posts"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["data"].length).to eq(1)
      expect(json["data"].first["title"]).to eq("Published Post")
    end

    it "includes category and tags" do
      get "/api/v1/posts"

      json = JSON.parse(response.body)
      post = json["data"].first

      expect(post["category"]).to eq({ "name" => "Technology", "slug" => "technology" })
      expect(post["tags"].length).to eq(2)
      expect(post["tags"].map { |t| t["name"] }).to contain_exactly("Ruby", "Rails")
    end

    it "does not include body in index" do
      get "/api/v1/posts"

      json = JSON.parse(response.body)
      expect(json["data"].first["body"]).to be_nil
    end

    it "includes pagination metadata" do
      get "/api/v1/posts"

      json = JSON.parse(response.body)
      expect(json["meta"]).to be_present
      expect(json["meta"]["current_page"]).to eq(1)
      expect(json["meta"]["per_page"]).to eq(20)
      expect(json["meta"]["total_entries"]).to eq(1)
    end
  end

  describe "GET /api/v1/posts?include_body=true" do
    it "includes body for published posts" do
      get "/api/v1/posts", params: { include_body: "true" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].first["body"]).to be_present
    end

    it "still excludes draft posts from the public feed" do
      get "/api/v1/posts", params: { include_body: "true" }

      json = JSON.parse(response.body)
      expect(json["data"].map { |p| p["title"] }).not_to include("Draft Post")
    end

    it "returns body nil without the param (default behavior unchanged)" do
      get "/api/v1/posts"

      json = JSON.parse(response.body)
      expect(json["data"].first["body"]).to be_nil
    end
  end

  describe "cover image serialization" do
    let(:cover_post) do
      post = create(:post, :published, title: "Covered Post")
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("fake png bytes"),
        filename: "cover.png",
        content_type: "image/png"
      )
      post.cover_image.attach(blob)
      post.reload
      post
    end

    before { cover_post }

    it "includes cover_image URL, content type, and byte size" do
      get "/api/v1/posts"

      json = JSON.parse(response.body)
      post = json["data"].find { |p| p["title"] == "Covered Post" }

      expect(post["cover_image"]).to be_present
      expect(post["cover_image_content_type"]).to eq("image/png")
      expect(post["cover_image_byte_size"]).to be_present
    end

    it "returns nil cover fields for posts without covers" do
      get "/api/v1/posts"

      json = JSON.parse(response.body)
      post = json["data"].find { |p| p["title"] == "Published Post" }

      expect(post["cover_image"]).to be_nil
      expect(post["cover_image_content_type"]).to be_nil
      expect(post["cover_image_byte_size"]).to be_nil
    end
  end

  describe "GET /api/v1/posts/:slug" do
    it "returns the post with body" do
      get "/api/v1/posts/#{published_post.slug}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["title"]).to eq("Published Post")
      expect(json["body"]).to be_present
    end

    it "returns 404 for non-existent post" do
      get "/api/v1/posts/non-existent-slug"

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Post not found")
    end

    it "returns 404 for draft posts" do
      get "/api/v1/posts/#{draft_post.slug}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
