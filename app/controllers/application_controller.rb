class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  include ActionController::MimeResponds
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def authenticate_user!
    token = extract_token_from_header
    if token
      decoded = decode_jwt(token)
      if decoded && decoded[:user_id]
        @current_user = User.find_by(id: decoded[:user_id])
      end
    end

    unless @current_user
      render json: { error: "Not authenticated" }, status: :unauthorized
    end
  end
  def current_user
    @current_user
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :email, :password, :password_confirmation ])
    devise_parameter_sanitizer.permit(:sign_in, keys: [ :email, :password ])
  end

  private

  def extract_token_from_header
    header = request.headers["Authorization"]
    return nil unless header&.start_with?("Bearer ")

    header.split(" ", 2).last
  end

  def decode_jwt(token)
    secret = ENV["JWT_SECRET_KEY"] || Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
    decoded = JWT.decode(token, secret, true, algorithm: "HS256")
    { user_id: decoded[0]["sub"] }
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  def generate_jwt(user)
    payload = {
      sub: user.id,
      iat: Time.now.to_i,
      exp: 24.hours.from_now.to_i
    }
    secret = ENV["JWT_SECRET_KEY"] || Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
    JWT.encode(payload, secret, "HS256")
  end

  def user_json(user)
    {
      id: user.id,
      email: user.email,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
