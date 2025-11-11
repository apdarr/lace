require "test_helper"

class ProcessStravaWebhookJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
  end

  test "queues FetchAndMatchStravaActivityJob on create event" do
    strava_activity_id = 12345678901

    assert_enqueued_with(job: FetchAndMatchStravaActivityJob) do
      ProcessStravaWebhookJob.perform_now(
        aspect_type: "create",
        object_id: strava_activity_id,
        owner_id: @user.strava_id
      )
    end
  end

  test "queues FetchAndMatchStravaActivityJob on update event" do
    strava_activity_id = 12345678902

    assert_enqueued_with(job: FetchAndMatchStravaActivityJob) do
      ProcessStravaWebhookJob.perform_now(
        aspect_type: "update",
        object_id: strava_activity_id,
        owner_id: @user.strava_id
      )
    end
  end

  test "queues DeleteStravaActivityJob on delete event" do
    strava_activity_id = 12345678903

    assert_enqueued_with(job: DeleteStravaActivityJob) do
      ProcessStravaWebhookJob.perform_now(
        aspect_type: "delete",
        object_id: strava_activity_id,
        owner_id: @user.strava_id
      )
    end
  end

  test "handles webhook for unknown user gracefully" do
    assert_no_enqueued_jobs do
      ProcessStravaWebhookJob.perform_now(
        aspect_type: "create",
        object_id: 123456789,
        owner_id: 999999999 # Non-existent Strava user ID
      )
    end
  end

  test "handles unknown aspect type" do
    assert_no_enqueued_jobs do
      ProcessStravaWebhookJob.perform_now(
        aspect_type: "unknown",
        object_id: 123456789,
        owner_id: @user.strava_id
      )
    end
  end
end
