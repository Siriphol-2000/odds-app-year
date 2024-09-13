require "test_helper"

class SupportControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get support_show_url
    assert_response :success
  end
end
