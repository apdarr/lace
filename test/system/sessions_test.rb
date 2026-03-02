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

    # Mock the Google provider for this test
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "100000000000000088888",
      info: {
        email: "systemtest@example.com",
        first_name: "System",
        last_name: "Tester",
        image: "https://lh3.googleusercontent.com/system.jpg"
      },
      credentials: {
        token: "google_system_token",
        refresh_token: "google_system_refresh",
        expires_at: 1.week.from_now.to_i,
        expires: true
      },
      extra: {
        raw_info: {
          email_verified: true
        }
      }
    })

    # Add middleware to add the omniauth.auth key to the environment
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:strava]
  end

  teardown do
    # Clear the mocks for other tests
    OmniAuth.config.mock_auth[:strava] = nil
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "visit the login page" do
    visit new_session_path
    assert_selector "h1", text: "Welcome to Lace"
    assert_button "Continue with Strava"
    assert_button "Continue with Google"
  end

  test "should sign in and sign out with Strava" do
    session_count = Session.count

    visit new_session_path
    click_button "Continue with Strava"

    # Check that we were redirected to the root path
    assert_current_path root_path
    assert_text "Successfully signed in!"
    assert_equal session_count + 1, Session.count
  end

  test "should sign in with Google" do
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]

    session_count = Session.count

    visit new_session_path
    click_button "Continue with Google"

    assert_current_path root_path
    assert_text "Successfully signed in!"
    assert_equal session_count + 1, Session.count

    user = User.find_by(google_uid: "100000000000000088888")
    assert_not_nil user
    assert_equal "systemtest@example.com", user.email_address
  end

  test "should sign out" do
    visit new_session_path
    click_button "Continue with Strava"
    assert_text "Successfully signed in!"

    click_button "Sign out"
    assert_current_path root_path
    assert_text "Successfully signed out!"
  end
end
