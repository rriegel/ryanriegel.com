class Api::TagsController < ApplicationController
  def index
    tags = Tag.includes(:posts).order(:name)
    render json: tags.map { |tag| tag_json(tag) }
  end

  def show
    tag = Tag.find_by!(slug: params[:slug])
    render json: tag_json(tag, include_posts: true)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Tag not found" }, status: :not_found
  end

  private

  def tag_json(tag, include_posts: false)
    published_posts = tag.posts.select { |p| p.published? }
    {
      id: tag.id,
      name: tag.name,
      slug: tag.slug,
      posts_count: published_posts.size,
      posts: include_posts ? published_posts.sort_by { |p| p.published_at || Time.at(0) }.reverse.map { |post| post_summary(post) } : nil
    }
  end

  def post_summary(post)
    {
      id: post.id,
      title: post.title,
      slug: post.slug,
      excerpt: post.excerpt,
      published_at: post.published_at
    }
  end
end
