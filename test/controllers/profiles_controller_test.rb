require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "edit redirects unauthenticated visitors to login" do
    get edit_profile_path

    assert_redirected_to new_session_path
  end

  test "edit renders for an authenticated user" do
    sign_in_as(users(:one))

    get edit_profile_path

    assert_response :success
  end

  test "update with valid params" do
    sign_in_as(users(:one))

    patch profile_path, params: { name: "Updated Name", email_address: "updated@example.com" }

    assert_redirected_to dashboard_path
    assert_equal "Updated Name", users(:one).reload.name
    assert_equal "updated@example.com", users(:one).email_address
  end

  test "update with invalid params" do
    sign_in_as(users(:one))

    patch profile_path, params: { name: "", email_address: users(:one).email_address }

    assert_response :unprocessable_entity
    assert_not_equal "", users(:one).reload.name
  end
end
