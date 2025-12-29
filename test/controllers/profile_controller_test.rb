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
    called = false

    StravaWebhookService.stub(:create_subscription, ->(user, _url) { called = user.id == @user.id }) do
      patch profile_path, params: { profile_settings: { enable_strava_webhooks: "1" } }
    end

    assert called, "expected create_subscription to be invoked"
    assert_redirected_to profile_path
    follow_redirect!
    assert_select "#notice", text: /enabled/i
  end

  test "disabling webhooks deletes subscription and redirects" do
    called = false

    StravaWebhookService.stub(:delete_subscription, ->(user) { called = user.id == @user.id }) do
      patch profile_path, params: { profile_settings: { enable_strava_webhooks: "0" } }
    end

    assert called, "expected delete_subscription to be invoked"
    assert_redirected_to profile_path
    follow_redirect!
    assert_select "#notice", text: /disabled/i
  end

  test "failure to enable shows alert" do
    StravaWebhookService.stub(:create_subscription, ->(_user, _url) { raise RegisterStravaWebhookJob::SubscriptionError, "fail" }) do
      patch profile_path, params: { profile_settings: { enable_strava_webhooks: "1" } }
    end

    assert_response :unprocessable_entity
    assert_select "#alert", text: /fail/
  end
end
