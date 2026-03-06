class UpdateCalendarEventJob < ApplicationJob
  queue_as :default

  def perform(activity_id)
    activity = Activity.find(activity_id)
    plan = activity.plan

    return unless plan&.calendar_sync_enabled?

    user = plan.user
    return unless user.has_google_access_token?

    service = GoogleCalendarService.new(user)
    service.update_event(activity)

    Rails.logger.info "Updated calendar event for activity #{activity_id}"
  rescue GoogleCalendarService::AuthenticationError => e
    Rails.logger.error "Google auth error updating calendar event for activity #{activity_id}: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error updating calendar event for activity #{activity_id}: #{e.message}"
    raise e
  end
end
