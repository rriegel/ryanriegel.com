require "rails_helper"

RSpec.describe "API::Uploads", type: :request do
  let(:user) { create(:user, password: "password123", password_confirmation: "password123") }
  let(:auth_headers) do
    post "/api/v1/login", params: { user: { email: user.email, password: "password123" } }, as: :json
    { "Authorization" => "Bearer #{response.parsed_body["data"]["token"]}" }
  end

  describe "POST /api/v1/uploads/create_blob" do
    context "when authenticated" do
      it "returns signed_id and url for a numeric blob id" do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("test image content"),
          filename: "test.png",
          content_type: "image/png"
        )

        post "/api/v1/uploads/create_blob",
          params: { blob_id: blob.id }, headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["signed_id"]).to be_present
        expect(response.parsed_body["url"]).to be_present
        expect(response.parsed_body["filename"]).to eq("test.png")
        expect(response.parsed_body["content_type"]).to eq("image/png")
      end

      it "returns signed_id and url for a signed id string" do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("test image content"),
          filename: "test.jpg",
          content_type: "image/jpeg"
        )

        post "/api/v1/uploads/create_blob",
          params: { blob_id: blob.signed_id }, headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["signed_id"]).to eq(blob.signed_id)
      end

      it "accepts the raw DirectUpload blob JSON payload" do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("test image content"),
          filename: "test.webp",
          content_type: "image/webp"
        )

        post "/api/v1/uploads/create_blob",
          params: { blob_id: { signed_id: blob.signed_id } }, headers: auth_headers, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["signed_id"]).to eq(blob.signed_id)
      end

      it "returns 404 for an unknown numeric id" do
        post "/api/v1/uploads/create_blob",
          params: { blob_id: 999_999_999 }, headers: auth_headers, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it "returns 400 for a garbage signed id" do
        post "/api/v1/uploads/create_blob",
          params: { blob_id: "not-a-valid-signed-id" }, headers: auth_headers, as: :json

        expect(response).to have_http_status(:bad_request)
      end

      it "returns 400 when blob_id is missing" do
        post "/api/v1/uploads/create_blob", params: {}, headers: auth_headers, as: :json

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when not authenticated" do
      it "returns 401" do
        post "/api/v1/uploads/create_blob", params: { blob_id: "anything" }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
