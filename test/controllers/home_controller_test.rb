require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows the landing page to unauthenticated visitors" do
    get root_path

    assert_response :success
  end

  test "redirects authenticated visitors to the dashboard" do
    sign_in_as(users(:one))

    get root_path

    assert_redirected_to dashboard_path
  end
end
