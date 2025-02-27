require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  setup do
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

  test "visit the login page" do
    visit new_session_path
    assert_selector "h1", text: "Sign in"
    assert_button "Sign in with Strava"
  end

  test "should sign in with Strava" do
    session_count = Session.count

    visit new_session_path
    click_button "Sign in with Strava"

    # Check that we were redirected to the root path
    assert_current_path root_path
    assert_text "Successfully signed in with Strava!"
    assert_equal session_count + 1, Session.count
  end
end
