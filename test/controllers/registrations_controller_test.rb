require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_registration_path
    assert_response :success
  end

  test "create with valid params" do
    assert_difference "User.count", 1 do
      post registration_path, params: { email_address: "new@example.com", password: "password", password_confirmation: "password" }
    end

    assert_redirected_to new_session_path
    assert_enqueued_email_with ConfirmationsMailer, :confirm, args: [ User.find_by(email_address: "new@example.com") ]

    follow_redirect!
    assert_notice "Check your email to confirm"

    refute User.find_by(email_address: "new@example.com").confirmed?
  end

  test "create with an already registered email_address" do
    assert_no_difference "User.count" do
      post registration_path, params: { email_address: users(:one).email_address, password: "password", password_confirmation: "password" }
    end

    assert_response :unprocessable_entity
  end

  test "create with mismatched password confirmation" do
    assert_no_difference "User.count" do
      post registration_path, params: { email_address: "new@example.com", password: "password", password_confirmation: "different" }
    end

    assert_response :unprocessable_entity
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
