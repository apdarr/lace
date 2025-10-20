class FetchAndMatchStravaActivityJob < ApplicationJob
  queue_as :default

  def perform(user_id, strava_activity_id)
    user = User.find(user_id)

    begin
      # Fetch activity details from Strava API
      activity_data = fetch_from_strava(user, strava_activity_id)

      # Store or update in StravaActivity table (raw Strava data)
      strava_activity = StravaActivity.find_or_create_by(user_id: user.id, strava_id: strava_activity_id) do |s|
        s.strava_athlete_id = activity_data.athlete.id
        s.activity_type = activity_data.sport_type
        s.distance = activity_data.distance
        s.start_date_local = activity_data.start_date_local
        s.webhook_payload = activity_data.to_h
        s.match_status = "unmatched"
      end

      # Update if it already existed
      strava_activity.update(
        activity_type: activity_data.sport_type,
        distance: activity_data.distance,
        start_date_local: activity_data.start_date_local,
        webhook_payload: activity_data.to_h
      )

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
