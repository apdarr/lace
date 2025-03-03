require "application_system_test_case"

class PlansTest < ApplicationSystemTestCase
  setup do
    @plan = plans(:one)
    @user = users(:one)
      # Mock the Strava provider for this test
      OmniAuth.config.mock_auth[:strava] = OmniAuth::AuthHash.new({
        provider: "strava",
        uid: "123456",
        info: {
          first_name: "Test",
          last_name: "User",
          email: "test@example.com",
          profile: "http://example.com/test_user.jpg"
        },
        credentials: {
          token: "mock_token",
          refresh_token: "mock_refresh_token",
          expires_at: 1.week.from_now.to_i
        }
      })

      # Add middleware to add the omniauth.auth key to the environment
      Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:strava]
  end

  teardown do
    # Clear the mock for other tests
    OmniAuth.config.mock_auth[:strava] = nil
  end

  test "should modify plans after sign in" do
    session_count = Session.count

    visit new_session_path
    click_button "Sign in with Strava"

    # Check that we were redirected to the root path
    assert_current_path root_path
    assert_text "Successfully signed in with Strava!"
    assert_equal session_count + 1, Session.count

    visit plans_url
    assert_selector "h1", text: "Plans"

    click_on "New plan"
    fill_in "plan[race_date]", with: @plan.race_date
    click_on "Create Plan"

    assert_text "Plan was successfully created"

    visit plan_url(@plan)
    click_on "Edit this plan", match: :first

    fill_in "plan[race_date]", with: @plan.race_date + 1.week
    click_on "Update Plan"

    assert_text "Plan was successfully updated"

    visit plan_url(@plan)

    # Verify calendar components exist
    assert_selector ".grid-cols-8" # Main calendar grid
    assert_selector "[data-activity-cell]" # Activity cells

    # Verify calendar headers
    assert_text "Week"
    assert_text "M"
    assert_text "Tu"
    assert_text "W"
    assert_text "Th"
    assert_text "F"
    assert_text "Sa"
    assert_text "Su"

    visit plan_url(@plan)
    click_on "Destroy this plan", match: :first
    assert_text "Plan was successfully destroyed"
  end

  # test "visiting the index" do
  #   visit plans_url
  #   debugger
  #   assert_selector "h1", text: "Plans"
  # end

  # test "should create plan" do
  #   visit plans_url
  #   click_on "New plan"

  #   # Only fill in race_date as that's the main field we need
  #   fill_in "plan[race_date]", with: @plan.race_date
  #   click_on "Create Plan"

  #   assert_text "Plan was successfully created"
  # end

  # test "should update Plan" do
  #   visit plan_url(@plan)
  #   click_on "Edit this plan", match: :first

  #   fill_in "plan[race_date]", with: @plan.race_date + 1.week
  #   click_on "Update Plan"

  #   assert_text "Plan was successfully updated"
  # end

  # test "should show Plan" do
  #   visit plan_url(@plan)

  #   # Verify calendar components exist
  #   assert_selector ".grid-cols-8" # Main calendar grid
  #   assert_selector "[data-activity-cell]" # Activity cells

  #   # Verify calendar headers
  #   assert_text "Week"
  #   assert_text "M"
  #   assert_text "Tu"
  #   assert_text "W"
  #   assert_text "Th"
  #   assert_text "F"
  #   assert_text "Sa"
  #   assert_text "Su"
  # end

  # test "should destroy Plan" do
  #   visit plan_url(@plan)
  #   click_on "Destroy this plan", match: :first
  #   assert_text "Plan was successfully destroyed"
  # end
end
