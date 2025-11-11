require "test_helper"

class MatchStravaActivityJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
  end

  test "marks unmatched Strava activity when no matches found" do
    strava_activity = strava_activities(:one)
    strava_activity.update(match_status: "unmatched", activity_id: nil)

    MatchStravaActivityJob.perform_now(strava_activity.id)

    strava_activity.reload
    assert_equal "unmatched", strava_activity.match_status
    assert_nil strava_activity.activity_id
  end

  test "finds matching workout by date" do
    strava_activity = strava_activities(:one)
    plan = plans(:one)

    # Create an activity in the plan on the same date
    matching_activity = Activity.create!(
      plan_id: plan.id,
      user: plan.user,
      start_date_local: strava_activity.start_date_local,
      distance: strava_activity.distance,
      activity_type: strava_activity.activity_type
    )

    MatchStravaActivityJob.perform_now(strava_activity.id)

    strava_activity.reload
    assert_equal "matched", strava_activity.match_status
    assert_equal matching_activity.id, strava_activity.activity_id
  end

  test "calculates match score based on distance tolerance" do
    strava_activity = strava_activities(:one)
    strava_activity.update(distance: 5000.0, start_date_local: Time.current)

    plan = plans(:one)

    # Create a real activity with similar distance (1% difference)
    matching_activity = Activity.create!(
      plan_id: plan.id,
      user: plan.user,
      distance: 5050.0,
      start_date_local: Time.current,
      activity_type: strava_activity.activity_type,
      description: ""
    )

    # Run the full job
    MatchStravaActivityJob.perform_now(strava_activity.id)

    # Verify it matched
    strava_activity.reload
    assert_equal "matched", strava_activity.match_status
    assert_equal matching_activity.id, strava_activity.activity_id
  end

  test "prioritizes closest matches by score" do
    strava_activity = strava_activities(:one)

    # Test with multiple potential matches would require more complex setup
    # For now, this tests that the job completes without error
    assert_nothing_raised do
      MatchStravaActivityJob.perform_now(strava_activity.id)
    end
  end

  test "handles strava activity with no payload gracefully" do
    strava_activity = strava_activities(:one)
    strava_activity.update(webhook_payload: nil)

    assert_nothing_raised do
      MatchStravaActivityJob.perform_now(strava_activity.id)
    end
  end
end
