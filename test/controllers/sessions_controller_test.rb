require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true

    @google_auth_hash = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "100000000000000055555",
      info: {
        email: "controller_test@example.com",
        first_name: "Controller",
        last_name: "Test",
        image: "https://lh3.googleusercontent.com/controller.jpg"
      },
      credentials: {
        token: "google_ctrl_token",
        refresh_token: "google_ctrl_refresh",
        expires_at: 1.week.from_now.to_i,
        expires: true
      },
      extra: {
        raw_info: {
          email_verified: true
        }
      }
    })

    @strava_auth_hash = OmniAuth::AuthHash.new({
      provider: "strava",
      uid: "555555555",
      info: {
        email: "strava_ctrl@example.com",
        first_name: "Strava",
        last_name: "Ctrl",
        profile: "https://example.com/strava_ctrl.jpg"
      },
      credentials: {
        token: "strava_ctrl_token",
        refresh_token: "strava_ctrl_refresh",
        expires_at: 1.week.from_now.to_i
      }
    })
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.mock_auth[:strava] = nil
  end

  test "google oauth callback creates a new user" do
    OmniAuth.config.mock_auth[:google_oauth2] = @google_auth_hash

    assert_difference("User.count") do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match "Successfully signed in!", response.body

    user = User.find_by(google_uid: "100000000000000055555")
    assert_not_nil user
    assert_equal "controller_test@example.com", user.email_address
    assert_equal "Controller", user.firstname
  end

  test "google oauth callback signs in existing google user" do
    existing = users(:google_user)
    @google_auth_hash.uid = existing.google_uid
    OmniAuth.config.mock_auth[:google_oauth2] = @google_auth_hash

    assert_no_difference("User.count") do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to root_path
  end

  test "google oauth callback auto-links to existing strava user by verified email" do
    strava_user = users(:one)
    @google_auth_hash.info.email = strava_user.email_address
    OmniAuth.config.mock_auth[:google_oauth2] = @google_auth_hash

    assert_no_difference("User.count") do
      get "/auth/google_oauth2/callback"
    end

    strava_user.reload
    assert_equal @google_auth_hash.uid, strava_user.google_uid
    assert_equal "google_ctrl_token", strava_user.google_access_token
    assert_redirected_to root_path
  end

  test "google oauth callback with unverified email creates new user" do
    strava_user = users(:one)
    @google_auth_hash.info.email = strava_user.email_address
    @google_auth_hash.extra.raw_info.email_verified = false
    OmniAuth.config.mock_auth[:google_oauth2] = @google_auth_hash

    assert_difference("User.count") do
      get "/auth/google_oauth2/callback"
    end

    new_user = User.find_by(google_uid: @google_auth_hash.uid)
    assert_not_equal strava_user.id, new_user.id
  end

  test "strava oauth callback still works" do
    OmniAuth.config.mock_auth[:strava] = @strava_auth_hash

    assert_difference("User.count") do
      get "/auth/strava/callback"
    end

    assert_redirected_to root_path
  end

  test "oauth failure redirects to login with error" do
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

    get "/auth/google_oauth2/callback"

    # OmniAuth redirects to /auth/failure which our controller handles
    assert_response :redirect
    follow_redirect!
    assert_redirected_to new_session_path
  end

  test "google oauth creates a session record" do
    OmniAuth.config.mock_auth[:google_oauth2] = @google_auth_hash

    assert_difference("Session.count") do
      get "/auth/google_oauth2/callback"
    end
  end

  test "linking strava to authenticated google user" do
    google_user = users(:google_user)
    sign_in_as(google_user)

    OmniAuth.config.mock_auth[:strava] = @strava_auth_hash
    Rails.application.env_config["omniauth.auth"] = @strava_auth_hash
    Rails.application.env_config["omniauth.origin"] = "link_strava"

    assert_no_difference("User.count") do
      get "/auth/strava/callback"
    end

    google_user.reload
    assert_equal @strava_auth_hash.uid.to_s, google_user.strava_id.to_s
    assert_equal "strava_ctrl_token", google_user.access_token
    assert google_user.strava_connected?
    assert_redirected_to edit_profile_path
    follow_redirect!
    assert_match "connected", response.body
  ensure
    Rails.application.env_config.delete("omniauth.origin")
    Rails.application.env_config.delete("omniauth.auth")
  end

  test "linking strava fails when strava account belongs to another user" do
    google_user = users(:google_user)
    sign_in_as(google_user)

    existing_strava_user = users(:one)
    @strava_auth_hash.uid = existing_strava_user.strava_id

    OmniAuth.config.mock_auth[:strava] = @strava_auth_hash
    Rails.application.env_config["omniauth.auth"] = @strava_auth_hash
    Rails.application.env_config["omniauth.origin"] = "link_strava"

    assert_no_difference("User.count") do
      get "/auth/strava/callback"
    end

    google_user.reload
    assert_not google_user.strava_connected?
    assert_redirected_to edit_profile_path
    follow_redirect!
    assert_match "already linked", response.body
  ensure
    Rails.application.env_config.delete("omniauth.origin")
    Rails.application.env_config.delete("omniauth.auth")
  end

  test "linking strava without authentication falls through to login" do
    OmniAuth.config.mock_auth[:strava] = @strava_auth_hash
    Rails.application.env_config["omniauth.origin"] = "link_strava"

    assert_difference("User.count") do
      get "/auth/strava/callback"
    end

    assert_redirected_to root_path
  ensure
    Rails.application.env_config.delete("omniauth.origin")
  end
end
