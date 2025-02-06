require "test_helper"

class PlanTest < ActiveSupport::TestCase
  test "before new plan is created, should call load_from_plan_template" do
    initial_count =  Activity.count
    # Call the Activity's load_from_plan_template method before a new plan is saved
    plan = Plan.new(length: 18, race_date: "2025-05-01")
    plan.save!
    assert Activity.count == 126 + initial_count
  end

  test "Activity plan should be create with the correct start date" do
    Plan.create(length: 18, race_date: "2025-05-24")
    expected_date = "2025-01-19"
    actual_date = Activity.last.start_date_local - 18.weeks
    assert_equal expected_date, actual_date.strftime("%Y-%m-%d")
  end
end
