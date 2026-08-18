require "rails_helper"

RSpec.describe Post, type: :model do
  describe "associations" do
    it { should belong_to(:category).optional }
    it { should have_many(:post_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:post_tags) }
  end

  describe "validations" do
    subject { build(:post) }

    it { should validate_presence_of(:title) }
    it { should validate_uniqueness_of(:title) }
    it { should validate_presence_of(:body) }
    it { should validate_presence_of(:status) }
  end

  describe "enums" do
    it { should define_enum_for(:status).with_values(draft: 0, published: 1) }
  end

  describe "scopes" do
    let!(:published_post) { create(:post, :published) }
    let!(:draft_post) { create(:post, status: :draft) }

    it "returns only published posts" do
      expect(Post.published).to include(published_post)
      expect(Post.published).not_to include(draft_post)
    end

    it "returns only draft posts" do
      expect(Post.drafts).to include(draft_post)
      expect(Post.drafts).not_to include(published_post)
    end
  end

  describe "slug generation" do
    it "auto-generates slug from title" do
      post = create(:post, title: "My Awesome Post")
      expect(post.slug).to eq("my-awesome-post")
    end

    it "does not override existing slug" do
      post = create(:post, title: "My Post", slug: "custom-slug")
      expect(post.slug).to eq("custom-slug")
    end
  end
end
