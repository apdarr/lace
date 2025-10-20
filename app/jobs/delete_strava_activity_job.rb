class DeleteStravaActivityJob < ApplicationJob
  queue_as :default

  def perform(user_id, strava_activity_id)
    strava_activity = StravaActivity.find_by(user_id: user_id, strava_id: strava_activity_id)

    if strava_activity
      strava_activity.destroy!
      Rails.logger.info "Deleted Strava activity record #{strava_activity_id} for user #{user_id}"
    else
      Rails.logger.warn "Strava activity #{strava_activity_id} not found for deletion"
    end
  end
end
