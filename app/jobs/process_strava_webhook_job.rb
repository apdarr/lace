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
      fetch_and_create_activity(user, object_id)
    when "update"
      fetch_and_update_activity(user, object_id)
    when "delete"
      delete_activity(object_id)
    else
      Rails.logger.warn "Unknown aspect_type: #{aspect_type}"
    end
  end

  private

  def fetch_and_create_activity(user, strava_activity_id)
    # Initialize Strava client with user's access token
    client = Strava::Api::Client.new(access_token: user.access_token)

    begin
      # Fetch activity details from Strava
      activity_data = client.activity(strava_activity_id)

      # Create activity in our database
      Activity.create!(
        strava_id: activity_data.id,
        distance: activity_data.distance,
        elapsed_time: activity_data.elapsed_time,
        kudos_count: activity_data.kudos_count,
        activity_type: activity_data.sport_type,
        average_heart_rate: activity_data.average_heartrate,
        max_heart_rate: activity_data.max_heartrate,
        start_date_local: activity_data.start_date_local,
        description: activity_data.description
      )

      Rails.logger.info "Created activity #{strava_activity_id} for user #{user.id}"
    rescue StandardError => e
      Rails.logger.error "Error fetching/creating activity #{strava_activity_id}: #{e.message}"
      raise e
    end
  end

  def fetch_and_update_activity(user, strava_activity_id)
    # Find existing activity
    activity = Activity.find_by(strava_id: strava_activity_id)

    unless activity
      Rails.logger.warn "Activity #{strava_activity_id} not found for update, creating instead"
      fetch_and_create_activity(user, strava_activity_id)
      return
    end

    # Initialize Strava client with user's access token
    client = Strava::Api::Client.new(access_token: user.access_token)

    begin
      # Fetch updated activity details from Strava
      activity_data = client.activity(strava_activity_id)

      # Update activity in our database
      activity.update!(
        distance: activity_data.distance,
        elapsed_time: activity_data.elapsed_time,
        kudos_count: activity_data.kudos_count,
        activity_type: activity_data.sport_type,
        average_heart_rate: activity_data.average_heartrate,
        max_heart_rate: activity_data.max_heartrate,
        start_date_local: activity_data.start_date_local,
        description: activity_data.description
      )

      Rails.logger.info "Updated activity #{strava_activity_id}"
    rescue StandardError => e
      Rails.logger.error "Error fetching/updating activity #{strava_activity_id}: #{e.message}"
      raise e
    end
  end

  def delete_activity(strava_activity_id)
    activity = Activity.find_by(strava_id: strava_activity_id)

    if activity
      activity.destroy!
      Rails.logger.info "Deleted activity #{strava_activity_id}"
    else
      Rails.logger.warn "Activity #{strava_activity_id} not found for deletion"
    end
  end
end
