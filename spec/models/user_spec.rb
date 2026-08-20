require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }

    it "requires password confirmation to match" do
      user = build(:user, password: "password123", password_confirmation: "different")
      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to include("doesn't match Password")
    end

    it "validates email format" do
      user = build(:user, email: "invalid-email")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it "accepts valid email formats" do
      valid_emails = [ "user@example.com", "user.name@example.com", "user+tag@example.com" ]
      valid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).to be_valid, "Expected #{email} to be valid"
      end
    end
  end

  describe "Devise modules" do
    it "includes database_authenticatable" do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it "includes registerable" do
      expect(User.devise_modules).to include(:registerable)
    end

    it "includes validatable" do
      expect(User.devise_modules).to include(:validatable)
    end

    it "includes jwt_authenticatable" do
      expect(User.devise_modules).to include(:jwt_authenticatable)
    end
  end

  describe "password validation" do
    it "authenticates with correct password" do
      user = create(:user, password: "password123", password_confirmation: "password123")
      expect(user.valid_password?("password123")).to be true
    end

    it "rejects incorrect password" do
      user = create(:user, password: "password123", password_confirmation: "password123")
      expect(user.valid_password?("wrongpassword")).to be false
    end

    it "rejects empty password" do
      user = create(:user, password: "password123", password_confirmation: "password123")
      expect(user.valid_password?("")).to be false
    end
  end

  describe "email uniqueness" do
    it "prevents duplicate emails with different cases" do
      create(:user, email: "user@example.com")
      duplicate = build(:user, email: "USER@example.com")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("has already been taken")
    end
  end
end
