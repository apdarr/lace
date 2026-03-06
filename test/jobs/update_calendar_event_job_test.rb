require "test_helper"

class UpdateCalendarEventJobTest < ActiveJob::TestCase
  setup do
    @plan = plans(:one)
    @activity = activities(:one)
    @activity.update_columns(plan_id: @plan.id)
  end

  test "skips update when plan has no calendar sync enabled" do
    @plan.update_columns(calendar_sync_enabled: false)

    assert_nothing_raised do
      UpdateCalendarEventJob.perform_now(@activity.id)
    end
  end

  test "skips update when activity has no plan" do
    @activity.update_columns(plan_id: nil)

    assert_nothing_raised do
      UpdateCalendarEventJob.perform_now(@activity.id)
    end
  end

  test "skips update when user has no Google credentials" do
    @plan.update_columns(calendar_sync_enabled: true)
    @plan.user.update_columns(google_access_token: nil)

    assert_nothing_raised do
      UpdateCalendarEventJob.perform_now(@activity.id)
    end
  end
end
