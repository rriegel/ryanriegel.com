class Api::PostsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]

  def index
    posts = Post.published.includes(:category, :tags).order(published_at: :desc)
    render json: posts.map { |post| post_json(post) }
  end

  def show
    post = Post.published.find_by!(slug: params[:slug])
    render json: post_json(post, full: true)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Post not found" }, status: :not_found
  end

  def create
    post = Post.new(post_params)
    if post.save
      render json: post_json(post, full: true), status: :created
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    post = Post.find_by!(slug: params[:slug])
    if post.update(post_params)
      render json: post_json(post, full: true)
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Post not found" }, status: :not_found
  end

  def destroy
    post = Post.find_by!(slug: params[:slug])
    post.destroy
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Post not found" }, status: :not_found
  end

  private

  def post_params
    params.require(:post).permit(:title, :body, :status, :category_id, :published_at, tag_ids: [])
  end

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
