require "application_system_test_case"

class PlansTest < ApplicationSystemTestCase
  setup do
    @plan = plans(:one)
    @user = users(:one)
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
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:strava]
  end

  teardown do
    OmniAuth.config.mock_auth[:strava] = nil
  end

  test "should return search result after sign in and search" do
    VCR.use_cassette("search_query") do
      session_count = Session.count

      visit new_session_path
      click_button "Continue with Strava"

      assert_current_path root_path
      assert_text "Successfully signed in with Strava!"
      assert_equal session_count + 1, Session.count

      visit activities_path

      fill_in "query", with: "activities longer than 10km"
      click_on "Search"

      assert_text "Showing results for: activities longer than 10km"
      assert_selector "#activities"

      # click_on "Clear search"
      # assert_no_text "Showing results for:"
    end
  end
end
