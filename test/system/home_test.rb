require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "visiting the root path" do
    visit root_url

    assert_selector "body"
  end
end
