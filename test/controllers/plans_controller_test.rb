require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @plan = plans(:one)
    @user = users(:one)

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
  end

  test "should create plan" do
    assert_difference("Plan.count") do
      post plans_url, params: { plan: { length: @plan.length, race_date: @plan.race_date, custom_creation: false } }
    end

    assert_redirected_to plan_url(Plan.last)
  end

  test "should create custom plan and redirect to edit" do
    assert_difference("Plan.count") do
      post plans_url, params: { plan: { length: 12, race_date: Date.today + 12.weeks, custom_creation: true } }
    end

    plan = Plan.last
    assert plan.custom_creation?
    assert_redirected_to edit_plan_url(plan)
  end

  test "should process photos for custom plan" do
    plan = plans(:custom_plan)
    
    # Mock file attachment
    photo = fixture_file_upload('test_image.jpg', 'image/jpeg')
    plan.photos.attach(photo)
    
    post process_photos_plan_url(plan)
    assert_redirected_to edit_plan_url(plan)
    
    # Should have activities created from the mock parser
    assert Activity.where(plan_id: plan.id).count > 0
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
    patch plan_url(@plan), params: { plan: { length: @plan.length, race_date: @plan.race_date, custom_creation: @plan.custom_creation } }
    assert_redirected_to plan_url(@plan)
  end

  test "should destroy plan" do
    assert_difference("Plan.count", -1) do
      delete plan_url(@plan)
    end

    assert_redirected_to plans_url
  end
end
