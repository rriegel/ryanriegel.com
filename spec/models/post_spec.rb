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

  describe "body sanitization" do
    # Regression: sanitize's `attributes:` option only accepts a flat list;
    # the per-tag hash previously passed was silently ignored, which stripped
    # EVERY attribute (img src/alt, a href) from stored bodies — inline images
    # vanished from the public blog view.
    it "preserves safe attributes on media tags" do
      post = create(:post, body: '<p>x <img src="/rails/active_storage/blobs/redirect/k/p.png" alt="cover" class="img-inline" loading="lazy"></p>')
      expect(post.body).to include('src="/rails/active_storage/blobs/redirect/k/p.png"')
      expect(post.body).to include('alt="cover"')
      expect(post.body).to include('class="img-inline"')
      expect(post.body).to include('loading="lazy"')
    end

    it "preserves safe attributes on links and video" do
      post = create(:post, body: '<p><a href="https://example.com">site</a> <video src="/v.mp4" controls poster="/p.jpg"></video></p>')
      expect(post.body).to include('href="https://example.com"')
      expect(post.body).to include('controls')
      expect(post.body).to include('poster="/p.jpg"')
    end

    it "strips javascript: URLs" do
      post = create(:post, body: '<img src="javascript:alert(1)"><a href="javascript:alert(1)">x</a>')
      expect(post.body).not_to include('javascript:')
      expect(post.body).not_to include('src=')
    end

    it "strips non-whitelisted attributes like onerror" do
      post = create(:post, body: '<img src="/safe.png" onerror="alert(1)">')
      expect(post.body).to include('src="/safe.png"')
      expect(post.body).not_to include('onerror')
    end

    it "keeps horizontal rules in position between paragraphs" do
      post = create(:post, body: '<p>alpha</p><hr><p>beta</p>')
      expect(post.body).to eq('<p>alpha</p><hr><p>beta</p>')
    end
  end
end
