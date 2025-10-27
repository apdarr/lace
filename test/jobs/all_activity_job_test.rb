require "test_helper"

class AllActivityJobTest < ActiveJob::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "should fetch and save activities" do
    StravaActivity.delete_all
    Activity.delete_all
    VCR.use_cassette("all_activity_job") do
      AllActivityJob.perform_now
    end
    assert_not_nil Activity.first
  end

  test "should enqueue the job" do
    assert_enqueued_with(job: AllActivityJob) do
      AllActivityJob.perform_later
    end
  end
end
