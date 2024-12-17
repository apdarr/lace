class AllActivityJob < ApplicationJob
  queue_as :default

  def perform(*args)
    batch_activities = fetch_all_activities
    import_activities(batch_activities)
  end

  private

  def fetch_all_activities
    client = Strava::Api::Client.new(access_token: ENV["STRAVA_TOKEN"])
    page = 1
    batch_activities = []
      begin
        sleep 1
        activities = client.athlete_activities(per_page: 30, page: page)
        # rate_limit_r = activities.http_response.rate_limit.to_h
        # token_expired = check_rate_limit(rate_limit_r)
        activities.each do |activity|
          # If there's data is non empty, process it
          if !activities.collection.empty? # && !token_expired
            batch_activities << {
              strava_id: activity.id,
              distance: activity.distance,
              elapsed_time: activity.elapsed_time,
              kudos_count: activity.kudos_count,
              activity_type: activity.sport_type,
              average_heart_rate: activity.average_heartrate,
              max_heart_rate: activity.max_heartrate,
              start_date_local: activity.start_date_local
            }
            page += 1
          else
            # Otherwise, we've reached the end of the data
            break
          end
        end
      rescue StandardError => e
        puts "Error fetching activities: #{e.message}"
      end
    batch_activities
  end

  def import_activities(batch_activities)
    # Note that upsert_all or insert_all ignore validations and callbacks!
    Activity.insert_all(batch_activities)
  end

  def check_rate_limit(rate_limit_r)
    rate_limit[:fifteen_minutes_remaining] > 0
  end
end
