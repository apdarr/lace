require "test_helper"
require "minitest/mock"

class ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "shows gear settings link on profile" do
    get profile_path
    assert_response :success
    assert_select "a", text: /⚙️ Settings/
  end

  test "edit displays settings form" do
    get edit_profile_path
    assert_response :success
    assert_select "form[action='#{profile_path}'][method='post']"
  end

  test "enabling webhooks creates subscription and redirects" do
    VCR.use_cassette("strava_webhook_register") do
      patch profile_path, params: { profile_settings: { enable_strava_webhooks: "1" } }

      assert_redirected_to profile_path
      follow_redirect!
      assert_select "#notice", text: /enabled/i

      @user.reload
      assert_not_nil @user.strava_webhook_subscription_id
      assert_not_nil @user.webhook_verify_token
    end
  end

  test "disabling webhooks deletes subscription and redirects" do
    @user.update!(strava_webhook_subscription_id: "12345")

    VCR.use_cassette("strava_webhook_delete") do
      patch profile_path, params: { profile_settings: { enable_strava_webhooks: "0" } }

      assert_redirected_to profile_path
      follow_redirect!
      assert_select "#notice", text: /disabled/i

      @user.reload
      assert_nil @user.strava_webhook_subscription_id
    end
  end

  # TODO: Record a VCR cassette for this test by triggering an actual Strava API failure
  # (e.g., use an invalid callback URL like "http://invalid" to get Strava to reject it)
  # test "failure to enable shows alert" do
  #   VCR.use_cassette("strava_webhook_register_failure") do
  #     patch profile_path, params: { profile_settings: { enable_strava_webhooks: "1" } }
  #
  #     assert_response :unprocessable_entity
  #     assert_select "#alert", text: /fail|error|invalid/i
  #   end
  # end
end
