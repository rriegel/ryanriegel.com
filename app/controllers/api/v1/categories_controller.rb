class Api::V1::CategoriesController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]

  def index
    categories = Category.includes(:posts).order(:name)
    render json: categories.map { |category| category_json(category) }
  end

  def show
    category = Category.find_by!(slug: params[:slug])
    render json: category_json(category, include_posts: true)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Category not found" }, status: :not_found
  end

  def create
    category = Category.new(category_params)
    if category.save
      render json: category_json(category), status: :created
    else
      render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    category = Category.find_by!(slug: params[:slug])
    if category.update(category_params)
      render json: category_json(category)
    else
      render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Category not found" }, status: :not_found
  end

  def destroy
    category = Category.find_by!(slug: params[:slug])
    category.destroy
    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Category not found" }, status: :not_found
  end

  private

  def category_params
    params.require(:category).permit(:name, :slug)
  end

  def category_json(category, include_posts: false)
    published_posts = category.posts.select { |p| p.published? }
    {
      id: category.id,
      name: category.name,
      slug: category.slug,
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
