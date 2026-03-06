class SyncPlanToCalendarJob < ApplicationJob
  queue_as :default

  def perform(plan_id)
    plan = Plan.find(plan_id)
    user = plan.user

    unless user.google_access_token.present?
      Rails.logger.warn "User #{user.id} has no Google credentials, skipping calendar sync"
      return
    end

    unless plan.calendar_sync_enabled?
      Rails.logger.info "Calendar sync not enabled for plan #{plan.id}, skipping"
      return
    end

    service = GoogleCalendarService.new(user)
    service.sync_plan(plan)

    Rails.logger.info "Successfully synced plan #{plan.id} to Google Calendar"
  rescue GoogleCalendarService::AuthenticationError => e
    Rails.logger.error "Google auth error syncing plan #{plan_id}: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error syncing plan #{plan_id} to calendar: #{e.message}"
    raise e
  end
end
