require "test_helper"

class ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "unconfirmed@example.com", password: "password", password_confirmation: "password")
  end

  test "new" do
    get new_confirmation_path
    assert_response :success
  end

  test "create" do
    post confirmations_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with ConfirmationsMailer, :confirm, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "Confirmation instructions sent"
  end

  test "create for an already confirmed user sends no mail" do
    @user.confirm!

    post confirmations_path, params: { email_address: @user.email_address }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path
  end

  test "create for an unknown user redirects but sends no mail" do
    post confirmations_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path
  end

  test "show with a valid token confirms and signs in the user" do
    token = @user.generate_token_for(:email_confirmation)

    get confirmation_path(token)

    assert @user.reload.confirmed?
    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "show with an invalid token" do
    get confirmation_path("invalid token")

    assert_redirected_to new_confirmation_path
    refute @user.reload.confirmed?

    follow_redirect!
    assert_notice "Confirmation link is invalid or has expired"
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
