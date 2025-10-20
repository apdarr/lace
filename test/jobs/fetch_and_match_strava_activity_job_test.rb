require "test_helper"

class FetchAndMatchStravaActivityJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
  end

  test "fetches and stores Strava activity" do
    strava_activity_id = 12345678901

    VCR.use_cassette("strava_activity_fetch") do
      assert_difference "StravaActivity.count", 1 do
        FetchAndMatchStravaActivityJob.perform_now(@user.id, strava_activity_id)
      end

      strava_activity = StravaActivity.find_by(strava_id: strava_activity_id)
      assert_not_nil strava_activity
      assert_equal @user.id, strava_activity.user_id
      assert_equal "unmatched", strava_activity.match_status
    end
  end

  test "queues MatchStravaActivityJob after fetching" do
    strava_activity_id = 12345678902

    VCR.use_cassette("strava_activity_fetch") do
      assert_enqueued_with(job: MatchStravaActivityJob) do
        FetchAndMatchStravaActivityJob.perform_now(@user.id, strava_activity_id)
      end
    end
  end

  test "updates existing Strava activity on re-fetch" do
    strava_activity = strava_activities(:one)

    VCR.use_cassette("strava_activity_fetch") do
      assert_no_difference "StravaActivity.count" do
        FetchAndMatchStravaActivityJob.perform_now(@user.id, strava_activity.strava_id)
      end

      strava_activity.reload
      assert_not_nil strava_activity.webhook_payload
    end
  end

  test "handles errors gracefully" do
    strava_activity_id = 999999999

    VCR.use_cassette("strava_activity_fetch_error") do
      assert_raises(StandardError) do
        FetchAndMatchStravaActivityJob.perform_now(@user.id, strava_activity_id)
      end
    end
  end
end
