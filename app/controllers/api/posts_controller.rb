class Api::PostsController < ApplicationController
  def index
    posts = Post.published.includes(:category, :tags).order(published_at: :desc)
    render json: posts.map { |post| post_json(post) }
  end

  def show
    post = Post.published.find_by!(slug: params[:slug])
    render json: post_json(post, full: true)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Post not found' }, status: :not_found
  end

  private

  def post_json(post, full: false)
    {
      id: post.id,
      title: post.title,
      slug: post.slug,
      excerpt: post.excerpt,
      body: full ? post.body : nil,
      status: post.status,
      published_at: post.published_at,
      category: post.category ? { name: post.category.name, slug: post.category.slug } : nil,
      tags: post.tags.map { |tag| { name: tag.name, slug: tag.slug } }
    }
  end
end
