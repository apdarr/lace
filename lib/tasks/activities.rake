namespace :activities do
  desc "Match all unmatched Strava activities to planned workouts"
  task match: :environment do
    puts "Starting batch matching for all unmatched activities..."
    result = BatchMatchActivitiesJob.perform_now
    puts "Batch matching completed:"
    puts "  - Matched: #{result[:matched]}"
    puts "  - Unmatched: #{result[:unmatched]}"
  end

  desc "Match unmatched Strava activities to workouts in a specific plan"
  task :match_plan, [:plan_id] => :environment do |_t, args|
    plan_id = args[:plan_id]
    
    if plan_id.blank?
      puts "Error: plan_id is required"
      puts "Usage: rails activities:match_plan[123]"
      exit 1
    end

    plan = Plan.find_by(id: plan_id)
    unless plan
      puts "Error: Plan with ID #{plan_id} not found"
      exit 1
    end

    puts "Starting batch matching for plan ##{plan_id}..."
    result = BatchMatchActivitiesJob.perform_now(plan_id)
    puts "Batch matching completed for plan ##{plan_id}:"
    puts "  - Matched: #{result[:matched]}"
    puts "  - Unmatched: #{result[:unmatched]}"
  end

  desc "Show unmatched activities"
  task unmatched: :environment do
    unmatched = Activity.unmatched
    puts "Found #{unmatched.count} unmatched Strava activities:"
    
    unmatched.limit(20).each do |activity|
      puts "  - Activity ##{activity.id} (Strava ID: #{activity.strava_id})"
      puts "    Date: #{activity.start_date_local&.to_date}"
      puts "    Distance: #{activity.distance}m"
      puts "    Type: #{activity.activity_type}"
      puts ""
    end
    
    if unmatched.count > 20
      puts "... and #{unmatched.count - 20} more"
    end
  end

  desc "Unmatch a specific activity from its workout"
  task :unmatch, [:activity_id] => :environment do |_t, args|
    activity_id = args[:activity_id]
    
    if activity_id.blank?
      puts "Error: activity_id is required"
      puts "Usage: rails activities:unmatch[123]"
      exit 1
    end

    activity = Activity.find_by(id: activity_id)
    unless activity
      puts "Error: Activity with ID #{activity_id} not found"
      exit 1
    end

    unless activity.matched?
      puts "Activity ##{activity_id} is not currently matched to any workout"
      exit 0
    end

    workout_id = activity.matched_workout_id
    matcher = ActivityMatcher.new(activity)
    if matcher.unmatch!
      puts "Successfully unmatched activity ##{activity_id} from workout ##{workout_id}"
    else
      puts "Failed to unmatch activity ##{activity_id}"
      exit 1
    end
  end
end
