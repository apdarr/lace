class DeleteCalendarEventJob < ApplicationJob
  queue_as :default

  def perform(user_id, calendar_id, event_id)
    user = User.find(user_id)

    return unless user.has_google_access_token?
    return if calendar_id.blank? || event_id.blank?

    service = GoogleCalendarService.new(user)
    service.delete_event(calendar_id, event_id)

    Rails.logger.info "Deleted calendar event #{event_id}"
  rescue GoogleCalendarService::AuthenticationError => e
    Rails.logger.error "Google auth error deleting calendar event #{event_id}: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error deleting calendar event #{event_id}: #{e.message}"
    raise e
  end
end
