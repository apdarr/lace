require "test_helper"

class MatchActivityJobTest < ActiveJob::TestCase
  def setup
    @plan = Plan.create!(
      length: 12,
      race_date: 3.months.from_now
    )
  end

  test "matches activity to workout with high confidence" do
    workout = Activity.create!(
      plan_id: @plan.id,
      distance: 5000.0,
      description: "Easy run",
      start_date_local: Date.today.to_time
    )

    activity = Activity.create!(
      strava_id: 123456789,
      distance: 5000.0,
      activity_type: "Run",
      start_date_local: Date.today.to_time
    )

    MatchActivityJob.perform_now(activity.id)
    activity.reload

    assert_equal workout.id, activity.matched_workout_id
    assert activity.match_confidence > 0
    assert_not_nil activity.matched_at
  end

  test "does not match when no suitable workout found" do
    Activity.create!(
      plan_id: @plan.id,
      distance: 5000.0,
      start_date_local: Date.today - 10.days
    )

    activity = Activity.create!(
      strava_id: 123456789,
      distance: 5000.0,
      start_date_local: Date.today.to_time
    )

    MatchActivityJob.perform_now(activity.id)
    activity.reload

    assert_nil activity.matched_workout_id
    assert_nil activity.match_confidence
  end

  test "skips already matched activities" do
    workout1 = Activity.create!(
      plan_id: @plan.id,
      distance: 5000.0,
      start_date_local: Date.today.to_time
    )

    workout2 = Activity.create!(
      plan_id: @plan.id,
      distance: 5000.0,
      start_date_local: Date.today.to_time
    )

    activity = Activity.create!(
      strava_id: 123456789,
      distance: 5000.0,
      matched_workout_id: workout1.id,
      match_confidence: 0.9,
      matched_at: Time.current,
      start_date_local: Date.today.to_time
    )

    MatchActivityJob.perform_now(activity.id)
    activity.reload

    # Should still be matched to workout1, not changed to workout2
    assert_equal workout1.id, activity.matched_workout_id
  end

  test "skips non-strava activities" do
    workout = Activity.create!(
      plan_id: @plan.id,
      distance: 5000.0,
      start_date_local: Date.today.to_time
    )

    MatchActivityJob.perform_now(workout.id)
    workout.reload

    assert_nil workout.matched_workout_id
  end

  test "handles missing activity gracefully" do
    assert_nothing_raised do
      MatchActivityJob.perform_now(999999)
    end
  end
end
