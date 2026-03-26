require "test_helper"

class Epic02RoutesTest < ActionDispatch::IntegrationTest
  test "GET / returns 200" do
    get "/"
    assert_response :success
  end

  test "GET /a-propos returns 200" do
    get "/a-propos"
    assert_response :success
  end

  test "GET /contact returns 200" do
    get "/contact"
    assert_response :success
  end

  test "GET /evenements returns 200" do
    # Skip - events route will be implemented in Epic 4
    skip "Events listing route not yet implemented (Epic 4)"
  end
end
