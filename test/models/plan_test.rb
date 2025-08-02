require "test_helper"

class PlanTest < ActiveSupport::TestCase
  test "before new plan is created, should call load_from_plan_template" do
    initial_count =  Activity.count
    # Call the Activity's load_from_plan_template method before a new plan is saved
    plan = Plan.new(length: 18, race_date: "2025-05-01", custom_creation: false)
    plan.save!
    assert Activity.count == 126 + initial_count
  end

  test "Activity plan should be create with the correct start date" do
    Plan.create(length: 18, race_date: "2025-05-24", custom_creation: false)
    expected_date = "2025-01-19"
    actual_date = Activity.last.start_date_local - 18.weeks
    assert_equal expected_date, actual_date.strftime("%Y-%m-%d")
  end

  test "custom plan should not load from template" do
    initial_count = Activity.count
    plan = Plan.new(length: 12, race_date: "2025-05-01", custom_creation: true)
    plan.save!
    # Should not create any activities from template
    assert_equal initial_count, Activity.count
  end

  test "plan should support photo attachments" do
    plan = plans(:custom_plan)
    assert plan.photos.respond_to?(:attach)
  end

  test "should create activities from parsed data" do
    plan = plans(:custom_plan)
    parsed_data = [{
      "weeks" => [{
        "week_number" => 1,
        "workouts" => {
          "monday" => {"distance" => 0, "description" => "Rest"},
          "tuesday" => {"distance" => 5, "description" => "Easy run"}
        }
      }]
    }]
    
    initial_count = Activity.where(plan_id: plan.id).count
    plan.create_activities_from_parsed_data(parsed_data)
    
    # Should have created 2 new activities (monday and tuesday)
    assert_equal initial_count + 2, Activity.where(plan_id: plan.id).count
  end
end
