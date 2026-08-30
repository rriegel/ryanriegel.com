class Api::V1::RegistrationsController < ApplicationController
  def create
    user = User.new(registration_params)

    if user.save
      token = generate_jwt(user)
      set_auth_cookie(token)
      render json: {
        status: { code: 200, message: "Signed up successfully." },
        data: { user: user_json(user), token: token }
      }, status: :ok
    else
      render json: {
        status: { code: 422, message: "User couldn't be created successfully." },
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def set_auth_cookie(token)
    cookies.signed[:auth_token] = {
      value: token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax,
      expires: 24.hours.from_now
    }
  end
end
