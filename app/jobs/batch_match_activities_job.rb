class BatchMatchActivitiesJob < ApplicationJob
  queue_as :default

  # Batch match all unmatched Strava activities to workouts
  # Optionally limited to matching workouts in a specific plan
  def perform(plan_id = nil)
    activities = Activity.unmatched

    matched_count = 0
    unmatched_count = 0

    activities.find_each do |activity|
      matcher = ActivityMatcher.new(activity)
      if matcher.match!(plan_id: plan_id)
        matched_count += 1
        Rails.logger.info "BatchMatchActivitiesJob: Matched activity #{activity.id} (confidence: #{activity.match_confidence})"
      else
        unmatched_count += 1
        Rails.logger.info "BatchMatchActivitiesJob: No match found for activity #{activity.id}"
      end
    end

    Rails.logger.info "BatchMatchActivitiesJob: Completed - #{matched_count} matched, #{unmatched_count} unmatched"
    
    {
      matched: matched_count,
      unmatched: unmatched_count
    }
  rescue StandardError => e
    Rails.logger.error "BatchMatchActivitiesJob failed: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise
  end
end
