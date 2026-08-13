require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated visitors to login" do
    get dashboard_path

    assert_redirected_to new_session_path
  end

  test "renders for an authenticated user" do
    sign_in_as(users(:one))

    get dashboard_path

    assert_response :success
  end
end
