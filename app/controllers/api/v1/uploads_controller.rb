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
  #
  # Status semantics:
  #   400 — missing/blank/malformed reference (client sent garbage)
  #   404 — well-formed reference that does not resolve to a blob
  def create_blob
    blob = find_blob!
    return render json: { error: "Blob not found" }, status: :not_found unless blob

    render json: {
      signed_id: blob.signed_id,
      url: rails_blob_url(blob),
      filename: blob.filename,
      content_type: blob.content_type,
      byte_size: blob.byte_size
    }
  rescue BlobReferenceMissing => e
    render json: { error: e.message }, status: :bad_request
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    Rails.logger.info("[UPLOADS] create_blob: invalid signature on blob reference")
    render json: { error: "Invalid blob reference" }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error("[UPLOADS] create_blob failed: #{e.class}: #{e.message}")
    render json: { error: "Blob lookup failed" }, status: :bad_request
  end

  private

  # Raised when the request carries no usable blob reference at all.
  class BlobReferenceMissing < StandardError; end

  # Resolves the request's blob reference to an ActiveStorage::Blob.
  # Raises BlobReferenceMissing when nothing usable was supplied;
  # raises InvalidSignature / RecordNotFound for unresolvable references.
  def find_blob!
    raw = params[:blob_id].presence || params[:blob].presence
    raise BlobReferenceMissing, "blob_id is required" if raw.blank?

    if raw.is_a?(ActionController::Parameters) || raw.is_a?(Hash)
      raw = raw["signed_id"].presence || raw["id"]
      raise BlobReferenceMissing, "blob_id has no signed_id or id" if raw.blank?
    end

    raw = raw.to_s
    raise BlobReferenceMissing, "blob_id is blank" if raw.blank?

    if raw.match?(/\A\d+\z/)
      ActiveStorage::Blob.find_by(id: raw.to_i)
    else
      # find_signed! (unlike find_signed) raises on invalid signatures;
      # find_signed would silently return nil and we'd wrongly 404
      ActiveStorage::Blob.find_signed!(raw)
    end
  rescue ActiveRecord::RecordNotFound
    # Well-formed reference (valid signature) to a nonexistent blob →
    # return nil so create_blob renders 404. Must be rescued HERE:
    # otherwise it falls through to the controller's StandardError
    # rescue and wrongly returns 400.
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
