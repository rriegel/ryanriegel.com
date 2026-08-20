require "rails_helper"

RSpec.describe "JWT Authentication Edge Cases", type: :request do
  let(:user) { create(:user) }
  let(:jwt_secret) do
    ENV["JWT_SECRET_KEY"] || Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
  end
  let(:valid_token) do
    payload = { sub: user.id, iat: Time.current.to_i, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, jwt_secret, "HS256")
  end

  describe "expired JWT token" do
    let(:expired_token) do
      payload = { sub: user.id, iat: 2.days.ago.to_i, exp: 1.day.ago.to_i }
      JWT.encode(payload, jwt_secret, "HS256")
    end

    it "returns 401 for expired token on protected endpoint" do
      post "/api/posts",
           params: { post: { title: "Test", body: "Body", status: "draft" } },
           headers: { "Authorization" => "Bearer #{expired_token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for expired token on write operation" do
      put "/api/posts/test-slug",
          params: { post: { title: "Updated" } },
          headers: { "Authorization" => "Bearer #{expired_token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "malformed Authorization header" do
    it "returns 401 when header has no Bearer prefix" do
      post "/api/posts",
           params: { post: { title: "Test", body: "Body", status: "draft" } },
           headers: { "Authorization" => valid_token }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when header is empty string" do
      post "/api/posts",
           params: { post: { title: "Test", body: "Body", status: "draft" } },
           headers: { "Authorization" => "" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when header has invalid format" do
      post "/api/posts",
           params: { post: { title: "Test", body: "Body", status: "draft" } },
           headers: { "Authorization" => "InvalidFormat" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when token is garbage" do
      post "/api/posts",
           params: { post: { title: "Test", body: "Body", status: "draft" } },
           headers: { "Authorization" => "Bearer not.a.valid.jwt.token" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when token has wrong signature" do
      payload = { sub: user.id, iat: Time.current.to_i, exp: 24.hours.from_now.to_i }
      wrong_secret = "wrong_secret_key"
      tampered_token = JWT.encode(payload, wrong_secret, "HS256")

      post "/api/posts",
           params: { post: { title: "Test", body: "Body", status: "draft" } },
           headers: { "Authorization" => "Bearer #{tampered_token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "valid JWT for deleted user" do
    let(:deleted_user_token) do
      deleted_user = create(:user)
      payload = { sub: deleted_user.id, iat: Time.current.to_i, exp: 24.hours.from_now.to_i }
      token = JWT.encode(payload, jwt_secret, "HS256")
      deleted_user.destroy
      token
    end

    it "returns 401 when user no longer exists" do
      post "/api/posts",
           params: { post: { title: "Test", body: "Body", status: "draft" } },
           headers: { "Authorization" => "Bearer #{deleted_user_token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for write operation when user no longer exists" do
      put "/api/posts/test-slug",
          params: { post: { title: "Updated" } },
          headers: { "Authorization" => "Bearer #{deleted_user_token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "JWT with missing or invalid payload" do
    it "returns 401 when token has no sub claim" do
      payload = { iat: Time.current.to_i, exp: 24.hours.from_now.to_i }
      token = JWT.encode(payload, jwt_secret, "HS256")

      post "/api/posts",
           params: { post: { title: "Test", body: "Body", status: "draft" } },
           headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when sub is non-existent user ID" do
      payload = { sub: 999_999, iat: Time.current.to_i, exp: 24.hours.from_now.to_i }
      token = JWT.encode(payload, jwt_secret, "HS256")

      post "/api/posts",
           params: { post: { title: "Test", body: "Body", status: "draft" } },
           headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when sub is nil" do
      payload = { sub: nil, iat: Time.current.to_i, exp: 24.hours.from_now.to_i }
      token = JWT.encode(payload, jwt_secret, "HS256")

      post "/api/posts",
           params: { post: { title: "Test", body: "Body", status: "draft" } },
           headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "public endpoints remain accessible" do
    it "allows GET /api/posts without authentication" do
      get "/api/posts"

      expect(response).to have_http_status(:ok)
    end

    it "allows GET /api/categories without authentication" do
      get "/api/categories"

      expect(response).to have_http_status(:ok)
    end

    it "allows GET /api/tags without authentication" do
      get "/api/tags"

      expect(response).to have_http_status(:ok)
    end
  end
end
