class Api::V1::UploadsController < ApplicationController
  before_action :authenticate_user!, only: [ :create_blob ]

  # POST /api/v1/uploads/create_blob
  #
  # Second leg of the ActiveStorage direct-upload flow. The browser has
  # already PUT the file bytes to the storage service via
  # /rails/active_storage/direct_uploads; this endpoint takes the resulting
  # blob reference and returns the signed_id (for attaching to posts as
  # cover_image_signed_id) plus a servable URL (for editor preview).
  #
  # Accepts any of: numeric blob id, signed id string, or the raw blob JSON
  # returned by DirectUpload#create.
  def create_blob
    raw = params[:blob_id].presence || params[:blob].presence
    return render json: { error: "blob_id is required" }, status: :bad_request if raw.blank?

    blob = find_blob(raw)
    return render json: { error: "Blob not found" }, status: :not_found unless blob

    render json: {
      signed_id: blob.signed_id,
      url: rails_blob_url(blob),
      filename: blob.filename,
      content_type: blob.content_type,
      byte_size: blob.byte_size
    }
  rescue StandardError => e
    Rails.logger.error("[UPLOADS] create_blob failed: #{e.class}: #{e.message}")
    render json: { error: "Blob lookup failed" }, status: :bad_request
  end

  private

  def find_blob(raw)
    if raw.is_a?(ActionController::Parameters) || raw.is_a?(Hash)
      raw = raw["signed_id"].presence || raw["id"]
    end

    raw = raw.to_s
    return nil if raw.blank?

    if raw.match?(/\A\d+\z/)
      ActiveStorage::Blob.find_by(id: raw.to_i)
    else
      ActiveStorage::Blob.find_signed(raw)
    end
  rescue ActiveStorage::Blob::SignedIdNotFound
    # Malformed identifier — re-raise so create_blob maps it to 400
    raise
  rescue ActiveRecord::RecordNotFound
    # Well-formed reference to a nonexistent blob → 404
    nil
  end

  def rails_blob_url(blob)
    if Rails.env.production? && ENV["ASSET_HOST"].present?
      Rails.application.routes.url_helpers.rails_blob_url(
        blob, host: ENV["ASSET_HOST"]
      )
    else
      Rails.application.routes.url_helpers.rails_blob_url(
        blob, host: request.host, port: request.port
      )
    end
  end
end
