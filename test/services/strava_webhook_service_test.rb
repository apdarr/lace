require "test_helper"

class StravaWebhookServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @callback_url = "https://example.com/webhooks/strava"
  end

  test "creates subscription successfully" do
    VCR.use_cassette("strava_webhook_create_subscription") do
      subscription_id = StravaWebhookService.create_subscription(@user, @callback_url)

      assert_not_nil subscription_id
      @user.reload
      assert_equal subscription_id, @user.strava_webhook_subscription_id
      assert_not_nil @user.webhook_verify_token
    end
  end

  test "raises error when subscription creation fails" do
    VCR.use_cassette("strava_webhook_create_subscription_failure") do
      assert_raises(StravaWebhookService::SubscriptionError) do
        StravaWebhookService.create_subscription(@user, "invalid_url")
      end
    end
  end

  test "deletes subscription successfully" do
    @user.update!(strava_webhook_subscription_id: "12345")

    VCR.use_cassette("strava_webhook_delete_subscription") do
      result = StravaWebhookService.delete_subscription(@user)

      assert result
      @user.reload
      assert_nil @user.strava_webhook_subscription_id
    end
  end

  test "handles delete when subscription already deleted (404)" do
    @user.update!(strava_webhook_subscription_id: "99999")

    VCR.use_cassette("strava_webhook_delete_subscription_not_found") do
      result = StravaWebhookService.delete_subscription(@user)

      assert result
      @user.reload
      assert_nil @user.strava_webhook_subscription_id
    end
  end

  test "returns early when no subscription ID exists" do
    @user.update!(strava_webhook_subscription_id: nil)

    result = StravaWebhookService.delete_subscription(@user)
    assert_nil result
  end

  test "lists subscriptions successfully" do
    VCR.use_cassette("strava_webhook_list_subscriptions") do
      subscriptions = StravaWebhookService.list_subscriptions

      assert_instance_of Array, subscriptions
    end
  end

  test "views subscription details successfully" do
    subscription_id = "12345"

    VCR.use_cassette("strava_webhook_view_subscription") do
      subscription = StravaWebhookService.view_subscription(subscription_id)

      assert_instance_of Hash, subscription
      assert_equal subscription_id, subscription["id"].to_s
    end
  end
end
