require "test_helper"

class DeleteStravaWebhookJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @user.update(strava_webhook_subscription_id: "12345")
  end

  test "deletes webhook subscription successfully" do
    VCR.use_cassette("strava_webhook_delete") do
      DeleteStravaWebhookJob.perform_now(@user.id)

      @user.reload
      assert_nil @user.strava_webhook_subscription_id
    end
  end

  test "handles subscription not found (404) gracefully" do
    @user.update(strava_webhook_subscription_id: "99999")

    VCR.use_cassette("strava_webhook_delete_not_found") do
      DeleteStravaWebhookJob.perform_now(@user.id)

      @user.reload
      assert_nil @user.strava_webhook_subscription_id
    end
  end

  test "returns early when no subscription ID exists" do
    @user.update(strava_webhook_subscription_id: nil)

    DeleteStravaWebhookJob.perform_now(@user.id)

    @user.reload
    assert_nil @user.strava_webhook_subscription_id
  end

  test "raises error on deletion failure" do
    VCR.use_cassette("strava_webhook_delete_failure") do
      assert_raises(DeleteStravaWebhookJob::SubscriptionError) do
        DeleteStravaWebhookJob.perform_now(@user.id)
      end
    end
  end
end
