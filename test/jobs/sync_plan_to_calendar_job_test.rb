require "test_helper"

class SyncPlanToCalendarJobTest < ActiveJob::TestCase
  setup do
    @plan = plans(:one)
  end

  test "skips sync when user has no Google credentials" do
    # Use update_columns to bypass encryption when clearing the token
    @plan.user.update_columns(google_access_token: nil)
    @plan.update_columns(calendar_sync_enabled: true)

    assert_nothing_raised do
      SyncPlanToCalendarJob.perform_now(@plan.id)
    end
  end

  test "skips sync when calendar sync is not enabled" do
    @plan.update_columns(calendar_sync_enabled: false)

    assert_nothing_raised do
      SyncPlanToCalendarJob.perform_now(@plan.id)
    end
  end
end
