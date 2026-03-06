class RemovePlanCalendarEventsJob < ApplicationJob
  queue_as :default

  def perform(plan_id)
    plan = Plan.find(plan_id)
    user = plan.user

    unless user.google_access_token.present?
      Rails.logger.warn "User #{user.id} has no Google credentials, skipping calendar event removal"
      return
    end

    service = GoogleCalendarService.new(user)
    service.remove_plan_events(plan)

    Rails.logger.info "Removed calendar events for plan #{plan_id}"
  rescue GoogleCalendarService::AuthenticationError => e
    Rails.logger.error "Google auth error removing calendar events for plan #{plan_id}: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error removing calendar events for plan #{plan_id}: #{e.message}"
    raise e
  end
end
