require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "matched_strava_activity returns matched strava activity" do
    activity = activities(:two)
    strava_activity = strava_activities(:two)

    assert_equal strava_activity, activity.matched_strava_activity
  end

  test "matched_strava_activity returns linked strava activity" do
    activity = activities(:two)
    strava_activity = strava_activities(:two)
    strava_activity.update!(match_status: "linked")

    assert_equal strava_activity, activity.matched_strava_activity
  end

  test "matched_strava_activity returns nil when no matched strava activity" do
    activity = activities(:one)

    assert_nil activity.matched_strava_activity
  end

  test "matched_strava_activity ignores unmatched strava activities" do
    activity = activities(:two)
    strava_activity = strava_activities(:two)
    strava_activity.update!(match_status: "unmatched")

    assert_nil activity.matched_strava_activity
  end

  test "enqueues UpdateCalendarEventJob when distance changes and calendar sync enabled" do
    user = users(:one)
    plan = plans(:one)
    # Use raw SQL to set token without triggering ActiveRecord encryption
    ActiveRecord::Base.connection.execute(
      "UPDATE users SET google_access_token = 'test_token', google_uid = 'test_uid' WHERE id = #{user.id}"
    )
    plan.update_columns(user_id: user.id, calendar_sync_enabled: true)
    activity = activities(:one)
    activity.update_columns(plan_id: plan.id, user_id: user.id)

    assert_enqueued_with(job: UpdateCalendarEventJob, args: [activity.id]) do
      activity.update!(distance: 10.0)
    end
  end

  test "does not enqueue UpdateCalendarEventJob when calendar sync is disabled" do
    plan = plans(:one)
    plan.update_columns(calendar_sync_enabled: false)
    activity = activities(:one)
    activity.update_columns(plan_id: plan.id)

    assert_no_enqueued_jobs(only: UpdateCalendarEventJob) do
      activity.update!(distance: 10.0)
    end
  end

  test "enqueues DeleteCalendarEventJob when activity with event_id is destroyed" do
    user = users(:one)
    plan = plans(:one)
    ActiveRecord::Base.connection.execute(
      "UPDATE users SET google_access_token = 'test_token', google_uid = 'test_uid', google_calendar_id = 'test_cal' WHERE id = #{user.id}"
    )
    plan.update_columns(user_id: user.id, calendar_sync_enabled: true)
    activity = activities(:one)
    activity.update_columns(plan_id: plan.id, user_id: user.id, google_calendar_event_id: "test_event_123")

    assert_enqueued_with(job: DeleteCalendarEventJob) do
      activity.destroy!
    end
  end

  test "does not enqueue DeleteCalendarEventJob when activity has no event_id" do
    activity = activities(:one)

    assert_no_enqueued_jobs(only: DeleteCalendarEventJob) do
      activity.destroy!
    end
  end
end
