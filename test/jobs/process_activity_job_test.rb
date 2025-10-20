require "test_helper"

class ProcessActivityJobTest < ActiveJob::TestCase
  test "creates new activity from activity data" do
    activity_data = {
      strava_id: 123456789,
      distance: 5000.0,
      elapsed_time: 1800,
      activity_type: "Run",
      start_date_local: Time.current
    }

    assert_difference "Activity.count", 1 do
      ProcessActivityJob.perform_now(activity_data)
    end

    activity = Activity.find_by(strava_id: 123456789)
    assert_not_nil activity
    assert_equal 5000.0, activity.distance
    assert_equal "Run", activity.activity_type
  end

  test "updates existing activity if strava_id matches" do
    existing_activity = Activity.create!(
      strava_id: 123456789,
      distance: 4000.0,
      start_date_local: Time.current
    )

    activity_data = {
      strava_id: 123456789,
      distance: 5000.0,
      elapsed_time: 1800,
      activity_type: "Run",
      start_date_local: Time.current
    }

    assert_no_difference "Activity.count" do
      ProcessActivityJob.perform_now(activity_data)
    end

    existing_activity.reload
    assert_equal 5000.0, existing_activity.distance
    assert_equal 1800, existing_activity.elapsed_time
  end

  test "enqueues MatchActivityJob for new unmatched activity" do
    activity_data = {
      strava_id: 123456789,
      distance: 5000.0,
      start_date_local: Time.current
    }

    assert_enqueued_with(job: MatchActivityJob) do
      ProcessActivityJob.perform_now(activity_data)
    end
  end

  test "does not enqueue MatchActivityJob for already matched activity" do
    workout = Activity.create!(
      plan_id: 1,
      distance: 5000.0,
      start_date_local: Date.today
    )

    existing_activity = Activity.create!(
      strava_id: 123456789,
      distance: 5000.0,
      matched_workout_id: workout.id,
      start_date_local: Time.current
    )

    activity_data = {
      strava_id: 123456789,
      distance: 5100.0,
      start_date_local: Time.current
    }

    assert_no_enqueued_jobs only: MatchActivityJob do
      ProcessActivityJob.perform_now(activity_data)
    end
  end
end
