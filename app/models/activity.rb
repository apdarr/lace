class Activity < ApplicationRecord
  has_neighbors :embedding

  belongs_to :plan, optional: true
  belongs_to :user, optional: true
  has_many :strava_activities, dependent: :destroy

  after_update :sync_calendar_event, if: :calendar_sync_needed?
  before_destroy :enqueue_calendar_event_deletion

  # Returns the first matched or linked StravaActivity, if any
  def matched_strava_activity
    strava_activities.where(match_status: %w[matched linked]).first
  end

  private

  def calendar_sync_needed?
    return false unless plan&.calendar_sync_enabled?
    return false unless plan&.user&.google_access_token.present?

    saved_change_to_distance? || saved_change_to_description? || saved_change_to_start_date_local?
  end

  def sync_calendar_event
    UpdateCalendarEventJob.perform_later(id)
  end

  def enqueue_calendar_event_deletion
    return unless google_calendar_event_id.present?
    return unless plan&.calendar_sync_enabled?

    user = plan&.user
    return unless user&.google_access_token.present?
    return unless user&.google_calendar_id.present?

    DeleteCalendarEventJob.perform_later(user.id, user.google_calendar_id, google_calendar_event_id)
  end
end
