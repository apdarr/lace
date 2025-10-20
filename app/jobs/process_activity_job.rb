class ProcessActivityJob < ApplicationJob
  queue_as :default

  # Process a Strava activity: create/update it and attempt to match to a workout
  def perform(activity_data, user_id = nil)
    activity = find_or_create_activity(activity_data)
    
    # Attempt to match to a planned workout
    MatchActivityJob.perform_later(activity.id) if activity.persisted? && !activity.matched?

    activity
  rescue StandardError => e
    Rails.logger.error "ProcessActivityJob failed for activity #{activity_data[:strava_id]}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise
  end

  private

  def find_or_create_activity(activity_data)
    # Find existing activity by strava_id or create new one
    activity = Activity.find_by(strava_id: activity_data[:strava_id])

    if activity
      # Update existing activity
      activity.update!(activity_data)
      Rails.logger.info "Updated existing activity #{activity.id} (Strava ID: #{activity_data[:strava_id]})"
    else
      # Create new activity
      activity = Activity.create!(activity_data)
      Rails.logger.info "Created new activity #{activity.id} (Strava ID: #{activity_data[:strava_id]})"
    end

    activity
  end
end
