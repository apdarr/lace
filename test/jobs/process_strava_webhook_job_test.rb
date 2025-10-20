require "test_helper"

class ProcessStravaWebhookJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
  end

  test "creates new activity on create event" do
    strava_activity_id = 12345678901

    VCR.use_cassette("strava_activity_fetch_create") do
      assert_difference "Activity.count", 1 do
        ProcessStravaWebhookJob.perform_now(
          aspect_type: "create",
          object_id: strava_activity_id,
          owner_id: @user.strava_id
        )
      end

      activity = Activity.find_by(strava_id: strava_activity_id)
      assert_not_nil activity
    end
  end

  test "updates existing activity on update event" do
    existing_activity = activities(:one)

    VCR.use_cassette("strava_activity_fetch_existing") do
      assert_no_difference "Activity.count" do
        ProcessStravaWebhookJob.perform_now(
          aspect_type: "update",
          object_id: existing_activity.strava_id,
          owner_id: @user.strava_id
        )
      end
    end
  end

  test "creates activity if not found on update event" do
    strava_activity_id = 12345678902

    VCR.use_cassette("strava_activity_fetch_update") do
      assert_difference "Activity.count", 1 do
        ProcessStravaWebhookJob.perform_now(
          aspect_type: "update",
          object_id: strava_activity_id,
          owner_id: @user.strava_id
        )
      end
    end
  end

  test "deletes activity on delete event" do
    activity_to_delete = activities(:one)

    assert_difference "Activity.count", -1 do
      ProcessStravaWebhookJob.perform_now(
        aspect_type: "delete",
        object_id: activity_to_delete.strava_id,
        owner_id: @user.strava_id
      )
    end

    assert_nil Activity.find_by(strava_id: activity_to_delete.strava_id)
  end

  test "handles delete event for non-existent activity" do
    assert_no_difference "Activity.count" do
      ProcessStravaWebhookJob.perform_now(
        aspect_type: "delete",
        object_id: 999999999,
        owner_id: @user.strava_id
      )
    end
  end

  test "handles webhook for unknown user" do
    assert_no_difference "Activity.count" do
      ProcessStravaWebhookJob.perform_now(
        aspect_type: "create",
        object_id: 123456789,
        owner_id: 999999999 # Non-existent Strava user ID
      )
    end
  end
end
