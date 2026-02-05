require "test_helper"

class ActivityTest < ActiveSupport::TestCase
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
end
