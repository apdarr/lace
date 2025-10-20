class ProcessStravaWebhookJob < ApplicationJob
  queue_as :default

  def perform(aspect_type:, object_id:, owner_id:)
    # Find the user by their Strava ID
    user = User.find_by(strava_id: owner_id)

    unless user
      Rails.logger.warn "Received webhook for unknown Strava user ID: #{owner_id}"
      return
    end

    case aspect_type
    when "create"
      # Queue job to fetch from Strava and store in StravaActivity
      FetchAndMatchStravaActivityJob.perform_later(user.id, object_id)
    when "update"
      # Queue job to fetch updated data from Strava
      FetchAndMatchStravaActivityJob.perform_later(user.id, object_id)
    when "delete"
      # Queue job to delete from StravaActivity tracking
      DeleteStravaActivityJob.perform_later(user.id, object_id)
    else
      Rails.logger.warn "Unknown aspect_type: #{aspect_type}"
    end
  end
end
