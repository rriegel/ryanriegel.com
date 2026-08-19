class Api::TagsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]

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

  def create
    tag = Tag.new(tag_params)
    if tag.save
      render json: tag_json(tag), status: :created
    else
      render json: { errors: tag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    tag = Tag.find_by!(slug: params[:slug])
    if tag.update(tag_params)
      render json: tag_json(tag)
    else
      render json: { errors: tag.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Tag not found" }, status: :not_found
  end

  def destroy
    tag = Tag.find_by!(slug: params[:slug])
    tag.destroy
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Tag not found" }, status: :not_found
  end

  private

  def tag_params
    params.require(:tag).permit(:name, :slug)
  end

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
