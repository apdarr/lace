require "test_helper"

class StravaWebhookServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @callback_url = "https://example.com/webhooks/strava"
  end

  test "queues RegisterStravaWebhookJob when creating subscription" do
    assert_enqueued_with(job: RegisterStravaWebhookJob) do
      StravaWebhookService.create_subscription(@user, @callback_url)
    end
  end

  test "queues DeleteStravaWebhookJob when deleting subscription" do
    @user.update!(strava_webhook_subscription_id: "12345")

    assert_enqueued_with(job: DeleteStravaWebhookJob) do
      StravaWebhookService.delete_subscription(@user)
    end
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

  test "raises error when listing subscriptions fails" do
    VCR.use_cassette("strava_webhook_list_subscriptions_error") do
      assert_raises(StravaWebhookService::SubscriptionError) do
        StravaWebhookService.list_subscriptions
      end
    end
  end
end
