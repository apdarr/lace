require "test_helper"

class RegisterStravaWebhookJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @callback_url = "https://example.com/webhooks/strava"
  end

  test "registers webhook subscription successfully" do
    VCR.use_cassette("strava_webhook_register") do
      RegisterStravaWebhookJob.perform_now(@user.id, @callback_url)

      @user.reload
      assert_not_nil @user.strava_webhook_subscription_id
      assert_not_nil @user.webhook_verify_token
    end
  end

  test "raises error on registration failure" do
    VCR.use_cassette("strava_webhook_register_failure") do
      assert_raises(RegisterStravaWebhookJob::SubscriptionError) do
        RegisterStravaWebhookJob.perform_now(@user.id, "invalid_url")
      end
    end
  end
end
