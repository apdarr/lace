require "google/apis/calendar_v3"

class GoogleCalendarService
  CALENDAR_SUMMARY = "Lace Training"
  CALENDAR_DESCRIPTION = "Training plan workouts synced from Lace"

  class Error < StandardError; end
  class AuthenticationError < Error; end

  def initialize(user)
    @user = user
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = build_authorization
  end

  # Find or create the Lace training calendar for the user
  def find_or_create_calendar
    if @user.google_calendar_id.present?
      begin
        calendar = @service.get_calendar(@user.google_calendar_id)
        return calendar.id
      rescue Google::Apis::ClientError => e
        Rails.logger.warn "Previously stored calendar not found (#{e.message}), creating new one"
        @user.update!(google_calendar_id: nil)
      end
    end

    calendar = Google::Apis::CalendarV3::Calendar.new(
      summary: CALENDAR_SUMMARY,
      description: CALENDAR_DESCRIPTION,
      time_zone: "America/New_York"
    )

    result = @service.insert_calendar(calendar)
    @user.update!(google_calendar_id: result.id)
    Rails.logger.info "Created Google Calendar '#{CALENDAR_SUMMARY}' for user #{@user.id}"

    result.id
  end

  # Create a calendar event for an activity
  def create_event(activity, calendar_id: nil)
    calendar_id ||= find_or_create_calendar

    event = build_event(activity)
    result = @service.insert_event(calendar_id, event)

    activity.update!(google_calendar_event_id: result.id)
    Rails.logger.info "Created calendar event #{result.id} for activity #{activity.id}"

    result
  end

  # Update an existing calendar event
  def update_event(activity, calendar_id: nil)
    return create_event(activity, calendar_id: calendar_id) if activity.google_calendar_event_id.blank?

    calendar_id ||= @user.google_calendar_id
    return unless calendar_id

    event = build_event(activity)

    begin
      result = @service.update_event(calendar_id, activity.google_calendar_event_id, event)
      Rails.logger.info "Updated calendar event #{result.id} for activity #{activity.id}"
      result
    rescue Google::Apis::ClientError => e
      if e.status_code == 404
        Rails.logger.warn "Calendar event not found, creating new one for activity #{activity.id}"
        activity.update!(google_calendar_event_id: nil)
        create_event(activity, calendar_id: calendar_id)
      else
        raise
      end
    end
  end

  # Delete a calendar event
  def delete_event(calendar_id, event_id)
    @service.delete_event(calendar_id, event_id)
    Rails.logger.info "Deleted calendar event #{event_id}"
  rescue Google::Apis::ClientError => e
    if e.status_code == 404
      Rails.logger.warn "Calendar event #{event_id} already deleted"
    else
      raise
    end
  end

  # Sync all activities for a plan to the calendar
  def sync_plan(plan)
    calendar_id = find_or_create_calendar

    plan.activities.find_each do |activity|
      next unless activity.start_date_local.present?

      if activity.google_calendar_event_id.present?
        update_event(activity, calendar_id: calendar_id)
      else
        create_event(activity, calendar_id: calendar_id)
      end
    end

    Rails.logger.info "Synced #{plan.activities.count} activities to Google Calendar for plan #{plan.id}"
  end

  # Remove all calendar events for a plan
  def remove_plan_events(plan)
    calendar_id = @user.google_calendar_id
    return unless calendar_id

    plan.activities.where.not(google_calendar_event_id: nil).find_each do |activity|
      delete_event(calendar_id, activity.google_calendar_event_id)
      activity.update!(google_calendar_event_id: nil)
    end

    Rails.logger.info "Removed calendar events for plan #{plan.id}"
  end

  private

  def build_event(activity)
    date = activity.start_date_local.to_date
    summary = build_event_summary(activity)

    Google::Apis::CalendarV3::Event.new(
      summary: summary,
      description: activity.description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date: date.to_s),
      end: Google::Apis::CalendarV3::EventDateTime.new(date: date.to_s),
      transparency: "transparent"
    )
  end

  def build_event_summary(activity)
    parts = []
    parts << "🏃"
    parts << "#{activity.distance} mi" if activity.distance.present? && activity.distance > 0
    parts << activity.activity_type if activity.activity_type.present?
    parts << "- #{activity.description}" if activity.description.present?
    parts.join(" ")
  end

  def build_authorization
    raise AuthenticationError, "User has no Google credentials" unless @user.google_access_token.present?

    refresh_google_token_if_needed!

    client = Signet::OAuth2::Client.new(
      access_token: @user.google_access_token,
      refresh_token: @user.google_refresh_token,
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      token_credential_uri: "https://oauth2.googleapis.com/token"
    )

    client
  end

  def refresh_google_token_if_needed!
    return if @user.google_token_expires_at.present? && @user.google_token_expires_at > Time.current

    client = Signet::OAuth2::Client.new(
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      token_credential_uri: "https://oauth2.googleapis.com/token",
      refresh_token: @user.google_refresh_token
    )

    client.fetch_access_token!

    @user.update!(
      google_access_token: client.access_token,
      google_token_expires_at: Time.current + client.expires_in.to_i.seconds
    )

    Rails.logger.info "Refreshed Google token for user #{@user.id}"
  rescue Signet::AuthorizationError => e
    Rails.logger.error "Failed to refresh Google token for user #{@user.id}: #{e.message}"
    raise AuthenticationError, "Failed to refresh Google token: #{e.message}"
  end
end
