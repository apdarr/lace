class FetchAndMatchStravaActivityJob < ApplicationJob
  queue_as :default

  # TODO re-do tests for this job after refactor
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

      match_to_activity(user_id, strava_activity.id, strava_activity.distance, strava_activity.start_date_local)
    rescue StandardError => e
      Rails.logger.error "Error fetching Strava activity #{strava_activity_id}: #{e.message}"
      raise e
    end
  end

  private

  def fetch_from_strava(user, strava_activity_id)
    client = Strava::Api::Client.new(access_token: user.fresh_access_token)
    activity = client.activity(strava_activity_id)

    activity
  end

  def match_to_activity(user_id, strava_activity_id, distance, start_date_local)
    # Convert Strava's default meters to miles
    distance = distance.to_f / 1609.34

    # For now, we just matched if the activity is within 0.5 miles, and we grab the first one we find
    matched_activity = Activity.where(user_id: user_id)
                               .where("distance BETWEEN ? AND ?", distance - 0.5, distance + 0.5)
                               .first

    strava_activity = StravaActivity.find(strava_activity_id)

    if matched_activity
      matched_activity.update(strava_activity_id: strava_activity.id)
      Rails.logger.info "Matched Strava activity #{strava_activity_id} to Activity #{matched_activity.id}"
    else
      Rails.logger.info "No matching Activity found for Strava activity #{strava_activity_id}"
    end
  end
end
