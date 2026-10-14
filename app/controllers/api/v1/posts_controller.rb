class Api::V1::PostsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]
  before_action :set_post, only: [ :update, :destroy ]
  # Auth MUST run before set_post_for_show: the draft visibility scope
  # depends on current_user.
  before_action :optional_authenticate_user!, only: [ :index, :show ]
  before_action :set_post_for_show, only: [ :show ]

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
    # Drafts are visible to authenticated users only (admin preview); for
    # anonymous visitors a draft is indistinguishable from a nonexistent
    # post (404 — no existence leak).
    return render json: { error: "Post not found" }, status: :not_found if @post.nil?

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
    if params[:post][:cover_image_signed_id].present?
      attach_cover_image_from_signed_id(@post)
      # Attaching touches the record, bumping lock_version in the DB out from
      # under the already-loaded @post — which would self-trigger
      # StaleObjectError (409) on the replace-cover save path. Re-sync the
      # optimistic-lock column from the DB before updating.
      @post.lock_version = Post.where(id: @post.id).pick(:lock_version)
    end

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

  # Drafts resolve for authenticated users (admin preview from the blog page
  # and the edit page); for anonymous users a draft is indistinguishable from
  # a nonexistent post (nil → 404 in the action).
  def set_post_for_show
    scope = current_user ? Post.all : Post.published
    @post = scope.find_by(slug: params[:slug])
  end

  def post_params
    # cover_image_signed_id is NOT a Post attribute — it drives the explicit
    # attach_cover_image_from_signed_id call below. Permitting it here would
    # mass-assign an unknown attribute (ActiveModel::UnknownAttributeError,
    # 500 on create/update). Same for :cover_image (an attachment, not a
    # column). Both are read from the raw params by the attach helper.
    params.require(:post).permit(:title, :body, :excerpt, :status, :category_id, :published_at, tag_ids: [])
  end

  def servable_blob_url(blob)
    if Rails.env.production? && ENV["ASSET_HOST"].present?
      Rails.application.routes.url_helpers.rails_blob_url(blob, host: ENV["ASSET_HOST"])
    else
      Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
    end
  end

  def attach_cover_image_from_signed_id(post)
    return unless params[:post][:cover_image_signed_id].present?

    begin
      blob = ActiveStorage::Blob.find_signed!(params[:post][:cover_image_signed_id])
      post.cover_image.attach(blob)
    rescue ActiveRecord::RecordNotFound
      # Invalid/unknown signed ID (find_signed! raises RecordNotFound, same as
      # uploads_controller#find_blob!) — post saves without a cover.
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
      # Relative blob path: same-origin in dev (rides the Astro proxy from any
      # browsing host) and correct under Astro's SSR fetch, where the Host Rails
      # sees is localhost:3000 regardless of the browser. Absolute URL only for
      # a production CDN host (see uploads_controller#servable_blob_url).
      cover_image: post.cover_image.attached? ? servable_blob_url(post.cover_image) : nil,
      category: post.category ? { name: post.category.name, slug: post.category.slug } : nil,
      tags: post.tags.map { |tag| { name: tag.name, slug: tag.slug } }
    }
  end
end
