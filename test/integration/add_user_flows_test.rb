require 'test_helper'

class AddUserFlowsTest < ActionDispatch::IntegrationTest
  test 'can see the ' do
    get '/'
    assert_select 'h1', 'Users List'
  end
end
