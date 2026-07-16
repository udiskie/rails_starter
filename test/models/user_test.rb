require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "email_address must be unique" do
    duplicate = User.new(email_address: users(:one).email_address, password: "password", password_confirmation: "password")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "confirmed? is false until confirm! is called" do
    user = User.create!(email_address: "unconfirmed@example.com", password: "password", password_confirmation: "password")
    assert_not user.confirmed?

    user.confirm!
    assert user.confirmed?
  end

  test "email_confirmation token is invalidated by a change of email_address" do
    user = users(:one)
    token = user.generate_token_for(:email_confirmation)

    user.update!(email_address: "changed@example.com")

    assert_nil User.find_by_token_for(:email_confirmation, token)
  end
end
