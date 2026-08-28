class Api::V1::SessionsController < ApplicationController
  before_action :authenticate_user!, only: [ :destroy ]

  def create
    user = User.find_by(email: params.dig(:user, :email))

    if user&.valid_password?(params.dig(:user, :password))
      token = generate_jwt(user)
      set_auth_cookie(token)
      render json: {
        status: { code: 200, message: "Logged in successfully." },
        data: { user: user_json(user) }
      }, status: :ok
    else
      render json: {
        status: { code: 401, message: "Invalid email or password." }
      }, status: :unauthorized
    end
  end

  def destroy
    if current_user
      clear_auth_cookie
      render json: {
        status: { code: 200, message: "Logged out successfully." }
      }, status: :ok
    else
      render json: {
        status: { code: 401, message: "Couldn't find an active session." }
      }, status: :unauthorized
    end
  end

  private

  def set_auth_cookie(token)
    cookies.signed[:auth_token] = {
      value: token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax,
      expires: 24.hours.from_now
    }
  end

  def clear_auth_cookie
    cookies.delete(:auth_token)
  end
end
