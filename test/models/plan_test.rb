require "test_helper"

class PlanTest < ActiveSupport::TestCase
  test "before new template plan is created, should call load_from_plan_template" do
    initial_count =  Activity.count
    # Call the Activity's load_from_plan_template method before a new plan is saved
    plan = Plan.new(length: 18, race_date: "2025-05-01", plan_type: "template")
    plan.save!
    assert Activity.count == 126 + initial_count
  end

  test "custom plan should not load from template" do
    initial_count = Activity.count
    plan = Plan.new(length: 18, race_date: "2025-05-01", plan_type: "custom")
    plan.save!
    assert_equal initial_count, Activity.count
  end

  test "Activity plan should be created with the correct start date" do
    Plan.create(length: 18, race_date: "2025-05-24", plan_type: "template")
    expected_date = "2025-01-19"
    actual_date = Activity.last.start_date_local - 18.weeks
    assert_equal expected_date, actual_date.strftime("%Y-%m-%d")
  end

  test "plan type defaults to template" do
    plan = Plan.new(length: 18, race_date: "2025-05-01")
    assert_equal "template", plan.plan_type
  end

  test "can create custom plan" do
    plan = Plan.new(length: 18, race_date: "2025-05-01", plan_type: "custom")
    assert plan.custom?
    assert_not plan.template?
  end
end
