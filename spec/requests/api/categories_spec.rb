require "rails_helper"

RSpec.describe "Api::Categories", type: :request do
  let!(:category1) { create(:category, name: "Technology") }
  let!(:category2) { create(:category, name: "Lifestyle") }
  let!(:published_post) { create(:post, :published, category: category1) }
  let!(:draft_post) { create(:post, :draft, category: category1) }

  describe "GET /api/v1/categories" do
    it "returns all categories" do
      get "/api/v1/categories"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json.length).to eq(2)
      expect(json.map { |c| c["name"] }).to contain_exactly("Technology", "Lifestyle")
    end

    it "includes published posts count" do
      get "/api/v1/categories"

      json = JSON.parse(response.body)
      tech = json.find { |c| c["name"] == "Technology" }

      expect(tech["posts_count"]).to eq(1)
    end

    it "does not include posts in index" do
      get "/api/v1/categories"

      json = JSON.parse(response.body)
      expect(json.first["posts"]).to be_nil
    end
  end

  describe "GET /api/v1/categories/:slug" do
    it "returns the category with posts" do
      get "/api/v1/categories/#{category1.slug}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["name"]).to eq("Technology")
      expect(json["posts"].length).to eq(1)
      expect(json["posts"].first["title"]).to eq(published_post.title)
    end

    it "only includes published posts" do
      get "/api/v1/categories/#{category1.slug}"

      json = JSON.parse(response.body)
      expect(json["posts"].length).to eq(1)
    end

    it "returns 404 for non-existent category" do
      get "/api/v1/categories/non-existent-slug"

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Category not found")
    end
  end
end
