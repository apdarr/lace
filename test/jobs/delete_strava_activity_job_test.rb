require "test_helper"

class DeleteStravaActivityJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @strava_activity = strava_activities(:one)
  end

  test "deletes Strava activity record" do
    assert_difference "StravaActivity.count", -1 do
      DeleteStravaActivityJob.perform_now(@user.id, @strava_activity.strava_id)
    end

    assert_nil StravaActivity.find_by(strava_id: @strava_activity.strava_id)
  end

  test "handles deletion of non-existent activity gracefully" do
    assert_no_difference "StravaActivity.count" do
      DeleteStravaActivityJob.perform_now(@user.id, 999999999)
    end
  end

  test "only deletes activity for correct user" do
    other_user = users(:two) || create_user
    other_strava_activity = strava_activities(:two) || create_strava_activity(other_user)

    assert_no_difference "StravaActivity.count" do
      DeleteStravaActivityJob.perform_now(@user.id, other_strava_activity.strava_id)
    end

    assert_not_nil StravaActivity.find_by(strava_id: other_strava_activity.strava_id)
  end
end
