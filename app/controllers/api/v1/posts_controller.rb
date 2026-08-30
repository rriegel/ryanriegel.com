class Api::V1::PostsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]
  before_action :set_post, only: [ :update, :destroy ]
  before_action :set_published_post, only: [ :show ]
  before_action :optional_authenticate_user!, only: [ :index ]

  def index
    # Admins can see all posts; public API only shows published
    posts = current_user ? Post.all : Post.published
    posts = posts.includes(:category, :tags)

    # Filtering
    posts = posts.where(category_id: params[:category_id]) if params[:category_id].present?
    posts = posts.joins(:tags).where(tags: { id: params[:tag_id] }) if params[:tag_id].present?
    posts = posts.where("published_at >= ?", params[:start_date]) if params[:start_date].present?
    posts = posts.where("published_at <= ?", params[:end_date]) if params[:end_date].present?
    
    # Status filter (admin only)
    if params[:status].present? && current_user
      posts = posts.where(status: params[:status]) unless params[:status] == "all"
    end

    # Sorting
    sort_by = params[:sort_by] || "published_at"
    sort_dir = params[:sort_dir] == "asc" ? :asc : :desc
    posts = case sort_by
            when "title" then posts.order(title: sort_dir)
            when "created_at" then posts.order(created_at: sort_dir)
            else posts.order(published_at: sort_dir)
            end

    # Pagination
    page = [ params[:page].to_i, 1 ].max
    per_page = [ [ params[:per_page].to_i, 20 ].max, 100 ].min
    offset = (page - 1) * per_page

    total = posts.count
    posts = posts.offset(offset).limit(per_page)

    render json: {
      data: posts.map { |post| post_json(post) },
      meta: {
        current_page: page,
        per_page: per_page,
        total_entries: total,
        total_pages: (total.to_f / per_page).ceil
      }
    }
  end

  def show
    render json: post_json(@post, full: true)
  end

  def create
    @post = Post.new(post_params)
    attach_cover_image_from_signed_id(@post)

    if @post.save
      render json: post_json(@post, full: true), status: :created
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    attach_cover_image_from_signed_id(@post) if params[:post][:cover_image_signed_id].present?

    if @post.update(post_params)
      render json: post_json(@post, full: true)
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::StaleObjectError
    render json: { error: "This post has been modified by someone else. Please reload and try again." }, status: :conflict
  end

  def destroy
    @post.destroy
    head :no_content
  end

  private

  def set_post
    @post = Post.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Post not found" }, status: :not_found
  end

  def set_published_post
    @post = Post.published.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Post not found" }, status: :not_found
  end

  def post_params
    params.require(:post).permit(:title, :body, :status, :category_id, :published_at, :cover_image, :cover_image_signed_id, tag_ids: [])
  end

  def attach_cover_image_from_signed_id(post)
    return unless params[:post][:cover_image_signed_id].present?

    begin
      blob = ActiveStorage::Blob.find_signed!(params[:post][:cover_image_signed_id])
      post.cover_image.attach(blob)
    rescue ActiveStorage::Blob::SignedIdNotFound
      # Invalid signed ID, will be caught by validation
    end
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
      lock_version: post.lock_version,
      cover_image: post.cover_image.attached? ? url_for(post.cover_image) : nil,
      category: post.category ? { name: post.category.name, slug: post.category.slug } : nil,
      tags: post.tags.map { |tag| { name: tag.name, slug: tag.slug } }
    }
  end
end
