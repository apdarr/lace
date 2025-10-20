require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @plan = plans(:one)
    @user = users(:one)

    # Always have a future date for tests
    race_date = Date.current + 30.days
    race_date = race_date.strftime("%Y-%m-%d")
    @plan.race_date = race_date
    @plan.save!

    @race_date = @plan.race_date

    sign_in_as(@user)
  end

  test "should get index" do
    sign_in_as(@user)
    get plans_url
    assert_response :success
  end

  test "should get new" do
    get new_plan_url
    assert_response :success
    assert_select "input[type=checkbox][name='plan[webhook_enabled]']"
  end

  test "should create plan" do
    assert_difference("Plan.count") do
      post plans_url, params: { plan: { length: @plan.length, race_date: @plan.race_date, plan_type: "template" } }
    end

    assert_redirected_to plan_url(Plan.last)
  end

  test "should create custom plan" do
    assert_difference("Plan.count") do
      post plans_url, params: { plan: { length: 12, race_date: @race_date, plan_type: "custom" } }
    end

    plan = Plan.last
    assert plan.custom?
    assert_redirected_to plan_url(plan)
  end

  test "should get edit_workouts for custom plan" do
    custom_plan = Plan.create!(length: 12, race_date: @race_date, plan_type: "custom")
    get edit_workouts_plan_url(custom_plan)
    assert_response :success
  end

  test "should update workouts" do
    # Always set race date in the future for tests
    plan = Plan.create!(length: 12, race_date: @race_date, plan_type: "custom")
    activity = Activity.create!(plan: plan, distance: 5.0, description: "Test run", start_date_local: Time.current)

    patch update_workouts_plan_url(plan), params: {
      activities: {
        activity.id => { distance: 6.0, description: "Updated run" }
      }
    }

    activity.reload
    assert_equal 6.0, activity.distance
    assert_equal "Updated run", activity.description
    assert_redirected_to plan_url(plan)
  end

  test "should show plan" do
    get plan_url(@plan)
    assert_response :success
  end

  test "should get edit" do
    get edit_plan_url(@plan)
    assert_response :success
  end

  test "should update plan" do
    patch plan_url(@plan), params: { plan: { length: @plan.length, race_date: @plan.race_date } }
    assert_redirected_to plan_url(@plan)
  end

  test "should destroy plan" do
    assert_difference("Plan.count", -1) do
      delete plan_url(@plan)
    end

    assert_redirected_to plans_url
  end

  test "should enable webhook sync" do
    skip "Requires webhook_enabled column in database" unless @plan.respond_to?(:webhook_enabled)
    
    patch enable_webhook_sync_plan_url(@plan)
    
    @plan.reload
    assert @plan.webhook_enabled
    assert_redirected_to plans_url
    assert_equal "Strava activity sync has been enabled for this plan.", flash[:notice]
  end

  test "should handle enable webhook sync when column doesn't exist" do
    skip "Only applicable when webhook_enabled column doesn't exist" if @plan.respond_to?(:webhook_enabled)
    
    patch enable_webhook_sync_plan_url(@plan)
    
    assert_redirected_to plans_url
    assert_match /not available yet/, flash[:alert]
  end
end
