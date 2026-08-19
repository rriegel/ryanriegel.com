class Api::RegistrationsController < ApplicationController
  def create
    user = User.new(registration_params)
    
    if user.save
      token = generate_jwt(user)
      response.set_header("Authorization", "Bearer #{token}")
      render json: {
        status: { code: 200, message: "Signed up successfully." },
        data: { user: user_json(user) }
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
end
