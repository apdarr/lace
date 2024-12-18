class AllActivityJob < ApplicationJob
  queue_as :default

  def perform(*args)
    fetch_all_activities
  end

  private

  def fetch_all_activities
    client = Strava::Api::Client.new(access_token: ENV["STRAVA_TOKEN"])
    page = 0
    activities_batch = []
    loop do
      begin
        page += 1
        activities = client.athlete_activities(per_page: 100, page: page)
        rate_limits = activities.http_response.ratelimit.to_h

        break if activities.collection.empty?
        if check_low_rate_limit(rate_limits)
          puts ("Backing off for rate limit, waiting 15 minutes")
          sleep 900
          next
        end

        activities.each do |activity|
          activities_batch << {
            strava_id: activity.id,
            distance: activity.distance,
            elapsed_time: activity.elapsed_time,
            kudos_count: activity.kudos_count,
            activity_type: activity.sport_type,
            average_heart_rate: activity.average_heartrate,
            max_heart_rate: activity.max_heartrate,
            start_date_local: activity.start_date_local
          }
        end

        puts "Importing batch of activities on page #{page}"
        import_activities(activities_batch)
        activities_batch = []
      rescue StandardError => e
        puts "Error fetching activities: #{e.message}"
      end
    end
    # Import any remaining activities
    import_activities(activities_batch) unless activities_batch.empty?
  end

  def import_activities(activities_batch)
    # Note that upsert_all or insert_all ignore validations and callbacks!
    Activity.insert_all(activities_batch)
  end

  def check_low_rate_limit(rate_limits)
    # Returns an integer
    fifteen_minutes_remaining = rate_limits[:fifteen_minutes_remaining]
    total_day_remaining = rate_limits[:total_day_remaining]

    # Returns true if we're close to the rate limit before next page
    fifteen_minutes_remaining <= 100 || total_day_remaining <= 100
  end
end
