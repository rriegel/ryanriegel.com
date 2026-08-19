class User < ApplicationRecord
  # Include default devise modules + JWT
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtNullRevocationStrategy
end
