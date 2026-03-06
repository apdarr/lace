require "test_helper"

class GoogleCalendarServiceTest < ActiveSupport::TestCase
  test "raises AuthenticationError when user has no Google credentials" do
    user = users(:one) # Strava-only user
    user.update_columns(google_access_token: nil, google_refresh_token: nil)

    assert_raises(GoogleCalendarService::AuthenticationError) do
      GoogleCalendarService.new(user)
    end
  end

  test "CALENDAR_SUMMARY is set" do
    assert_equal "Lace Training", GoogleCalendarService::CALENDAR_SUMMARY
  end

  test "CALENDAR_DESCRIPTION is set" do
    assert_equal "Training plan workouts synced from Lace", GoogleCalendarService::CALENDAR_DESCRIPTION
  end

  test "error classes are defined" do
    assert GoogleCalendarService::Error < StandardError
    assert GoogleCalendarService::AuthenticationError < GoogleCalendarService::Error
  end
end
