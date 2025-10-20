class MatchActivityJob < ApplicationJob
  queue_as :default

  # Attempt to match a Strava activity to a planned workout
  def perform(activity_id)
    activity = Activity.find(activity_id)

    unless activity.strava_activity?
      Rails.logger.warn "MatchActivityJob: Activity #{activity_id} is not a Strava activity, skipping"
      return
    end

    if activity.matched?
      Rails.logger.info "MatchActivityJob: Activity #{activity_id} already matched, skipping"
      return
    end

    matcher = ActivityMatcher.new(activity)
    if matcher.match!
      Rails.logger.info "MatchActivityJob: Successfully matched activity #{activity_id} to workout #{activity.matched_workout_id} (confidence: #{activity.match_confidence})"
    else
      Rails.logger.info "MatchActivityJob: No suitable match found for activity #{activity_id}"
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "MatchActivityJob: Activity #{activity_id} not found"
  rescue StandardError => e
    Rails.logger.error "MatchActivityJob failed for activity #{activity_id}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise
  end
end
