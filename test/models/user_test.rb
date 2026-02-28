require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @google_auth = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "100000000000000099999",
      info: {
        email: "newgoogle@example.com",
        first_name: "New",
        last_name: "Googler",
        image: "https://lh3.googleusercontent.com/new_photo.jpg"
      },
      credentials: {
        token: "google_access_token_new",
        refresh_token: "google_refresh_token_new",
        expires_at: 1.week.from_now.to_i,
        expires: true
      },
      extra: {
        raw_info: {
          email_verified: true
        }
      }
    })
  end

  test "find_or_create_from_google creates a new user" do
    assert_difference("User.count") do
      user = User.find_or_create_from_google(@google_auth)
      assert user.persisted?
      assert_equal "100000000000000099999", user.google_uid
      assert_equal "newgoogle@example.com", user.email_address
      assert_equal "New", user.firstname
      assert_equal "Googler", user.lastname
      assert_equal "google_access_token_new", user.google_access_token
      assert_equal "google_refresh_token_new", user.google_refresh_token
      assert_not_nil user.google_token_expires_at
    end
  end

  test "find_or_create_from_google finds existing user by google_uid" do
    existing = users(:google_user)
    @google_auth.uid = existing.google_uid

    assert_no_difference("User.count") do
      user = User.find_or_create_from_google(@google_auth)
      assert_equal existing.id, user.id
      assert_equal "google_access_token_new", user.reload.google_access_token
    end
  end

  test "find_or_create_from_google auto-links by verified email" do
    strava_user = users(:one)
    @google_auth.info.email = strava_user.email_address

    assert_no_difference("User.count") do
      user = User.find_or_create_from_google(@google_auth)
      assert_equal strava_user.id, user.id
      assert_equal @google_auth.uid, user.reload.google_uid
      assert_equal "google_access_token_new", user.google_access_token
    end
  end

  test "find_or_create_from_google does not auto-link when email is unverified" do
    strava_user = users(:one)
    @google_auth.info.email = strava_user.email_address
    @google_auth.extra.raw_info.email_verified = false

    assert_difference("User.count") do
      user = User.find_or_create_from_google(@google_auth)
      assert_not_equal strava_user.id, user.id
      assert user.persisted?
    end
  end

  test "find_or_create_from_google updates tokens on repeat sign-in" do
    existing = users(:google_user)
    @google_auth.uid = existing.google_uid
    @google_auth.credentials.token = "updated_token"
    @google_auth.credentials.refresh_token = "updated_refresh"

    User.find_or_create_from_google(@google_auth)
    existing.reload

    assert_equal "updated_token", existing.google_access_token
    assert_equal "updated_refresh", existing.google_refresh_token
  end

  test "strava_connected? returns true when strava_id is present" do
    assert users(:one).strava_connected?
    assert users(:linked_user).strava_connected?
  end

  test "strava_connected? returns false when strava_id is absent" do
    assert_not users(:google_user).strava_connected?
  end

  test "link_strava! sets strava credentials on user" do
    user = users(:google_user)
    auth = OmniAuth::AuthHash.new({
      provider: "strava",
      uid: "777888999",
      credentials: {
        token: "new_strava_token",
        refresh_token: "new_strava_refresh",
        expires_at: 1.week.from_now.to_i
      }
    })

    user.link_strava!(auth)
    user.reload

    assert_equal 777888999, user.strava_id
    assert_equal "new_strava_token", user.access_token
    assert_equal "new_strava_refresh", user.refresh_token
    assert_not_nil user.token_expires_at
    assert user.strava_connected?
  end
end
