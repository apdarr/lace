require "application_system_test_case"

class ActivitiesTest < ApplicationSystemTestCase
  setup do
    @activity = activities(:one)
  end

  test "visiting the index" do
    visit activities_url
    assert_selector "h1", text: "Activities"
  end

  test "should create activity" do
    visit activities_url
    click_on "New activity"

    fill_in "Average heart rate", with: @activity.average_heart_rate
    fill_in "Description", with: @activity.description
    fill_in "Distance", with: @activity.distance
    fill_in "Elapsed time", with: @activity.elapsed_time
    fill_in "Kudos count", with: @activity.kudos_count
    fill_in "Max heart rate", with: @activity.max_heart_rate
    fill_in "Activity Type", with: @activity.activity_type
    click_on "Create Activity"

    assert_text "Activity was successfully created"
    click_on "Back"
  end

  test "should update Activity" do
    visit activity_url(@activity)
    click_on "Edit this activity", match: :first

    fill_in "Average heart rate", with: @activity.average_heart_rate
    fill_in "Description", with: @activity.description
    fill_in "Distance", with: @activity.distance
    fill_in "Elapsed time", with: @activity.elapsed_time
    fill_in "Kudos count", with: @activity.kudos_count
    fill_in "Max heart rate", with: @activity.max_heart_rate
    fill_in "Activity Type", with: @activity.activity_type
    click_on "Update Activity"

    assert_text "Activity was successfully updated"
    click_on "Back"
  end

  test "should destroy Activity" do
    visit activity_url(@activity)
    click_on "Destroy this activity", match: :first

    assert_text "Activity was successfully destroyed"
  end
end
