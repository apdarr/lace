require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @activity = activities(:one)
    @user = users(:one)

    sign_in_as(@user)
  end

  test "should get index" do
    get activities_url
    assert_response :success
  end
  test "should show activity" do
    get activity_url(@activity)
    assert_response :success
  end

  test "should get edit" do
    get edit_activity_url(@activity)
    assert_response :success
  end

  test "should update activity" do
    patch activity_url(@activity), params: { activity: { average_heart_rate: @activity.average_heart_rate, description: @activity.description, distance: @activity.distance, elapsed_time: @activity.elapsed_time, kudos_count: @activity.kudos_count, max_heart_rate: @activity.max_heart_rate, activity_type: @activity.activity_type } }
    assert_redirected_to activity_url(@activity)
  end

  test "should destroy activity" do
    assert_difference("Activity.count", -1) do
      delete activity_url(@activity)
    end

    assert_redirected_to activities_url
  end
end
