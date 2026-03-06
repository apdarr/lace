require "test_helper"

class DeleteCalendarEventJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
  end

  test "skips deletion when user has no Google credentials" do
    @user.update_columns(google_access_token: nil)

    assert_nothing_raised do
      DeleteCalendarEventJob.perform_now(@user.id, "calendar_123", "event_456")
    end
  end

  test "skips deletion when calendar_id is blank" do
    assert_nothing_raised do
      DeleteCalendarEventJob.perform_now(@user.id, nil, "event_456")
    end
  end

  test "skips deletion when event_id is blank" do
    assert_nothing_raised do
      DeleteCalendarEventJob.perform_now(@user.id, "calendar_123", nil)
    end
  end
end
