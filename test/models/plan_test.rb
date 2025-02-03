require "test_helper"

class PlanTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "before new plan is created, should call load_from_plan_template" do
    # Initial count

    # Call the Activity's load_from_plan_template method before a new plan is created
    Plan.create("name": "Test", race_date: "2025-05-01")
    # After creation, there should be 126 activities
    assert Activity.count == 126
  end
end
