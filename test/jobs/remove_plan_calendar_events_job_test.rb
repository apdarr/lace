require "test_helper"

class RemovePlanCalendarEventsJobTest < ActiveJob::TestCase
  setup do
    @user = users(:linked_user)
    @plan = plans(:one)
    @plan.update_columns(user_id: @user.id)
  end

  test "skips removal when user has no Google credentials" do
    @user.update_columns(google_access_token: nil)

    assert_nothing_raised do
      RemovePlanCalendarEventsJob.perform_now(@plan.id)
    end
  end
end
