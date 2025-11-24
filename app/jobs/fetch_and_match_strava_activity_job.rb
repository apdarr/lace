class FetchAndMatchStravaActivityJob < ApplicationJob
  queue_as :default

  def perform(user_id, strava_activity_id)
    user = User.find(user_id)

    begin
      # Fetch activity details from Strava API
      activity_data = fetch_from_strava(user, strava_activity_id)

      # Store or update in StravaActivity table (raw Strava data)
      strava_activity = StravaActivity.find_or_initialize_by(user_id: user.id, strava_id: strava_activity_id)
      strava_activity.strava_athlete_id = activity_data.athlete.id
      strava_activity.activity_type = activity_data.sport_type
      strava_activity.distance = activity_data.distance
      strava_activity.start_date_local = activity_data.start_date_local
      strava_activity.webhook_payload = activity_data.to_h
      strava_activity.match_status ||= "unmatched"
      strava_activity.save!
      Rails.logger.info "Stored Strava activity #{strava_activity_id} for user #{user.id}"

      # Queue matching job to find potential linked workouts
      MatchStravaActivityJob.perform_later(strava_activity.id)
    rescue StandardError => e
      Rails.logger.error "Error fetching Strava activity #{strava_activity_id}: #{e.message}"
      raise e
    end
  end

  private

  def fetch_from_strava(user, strava_activity_id)
    client = Strava::Api::Client.new(access_token: user.access_token)
    client.activity(strava_activity_id)
  end
end
