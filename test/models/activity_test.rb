require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "should create data from plan template" do
    initial_count = Activity.count
    Activity.load_from_plan_template(Plan.first)
    post_load_count = Activity.count
    assert post_load_count - initial_count == 126
  end
end
