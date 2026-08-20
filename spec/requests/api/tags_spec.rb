require "rails_helper"

RSpec.describe "Api::Tags", type: :request do
  let!(:tag1) { create(:tag, name: "Ruby") }
  let!(:tag2) { create(:tag, name: "Rails") }
  let!(:published_post) { create(:post, :published, tags: [ tag1 ]) }
  let!(:draft_post) { create(:post, :draft, tags: [ tag1, tag2 ]) }

  describe "GET /api/tags" do
    it "returns all tags" do
      get "/api/tags"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json.length).to eq(2)
      expect(json.map { |t| t["name"] }).to contain_exactly("Ruby", "Rails")
    end

    it "includes published posts count" do
      get "/api/tags"

      puts "Response body: #{response.body}"
      json = JSON.parse(response.body)
      ruby_tag = json.find { |t| t["name"] == "Ruby" }

      expect(ruby_tag["posts_count"]).to eq(1)
    end

    it "does not include posts in index" do
      get "/api/tags"

      json = JSON.parse(response.body)
      expect(json.first["posts"]).to be_nil
    end
  end

  describe "GET /api/tags/:slug" do
    it "returns the tag with posts" do
      get "/api/tags/#{tag1.slug}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["name"]).to eq("Ruby")
      expect(json["posts"].length).to eq(1)
      expect(json["posts"].first["title"]).to eq(published_post.title)
    end

    it "only includes published posts" do
      get "/api/tags/#{tag1.slug}"

      json = JSON.parse(response.body)
      expect(json["posts"].length).to eq(1)
    end

    it "returns 404 for non-existent tag" do
      get "/api/tags/non-existent-slug"

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Tag not found")
    end
  end
end
