class MatchStravaActivityJob < ApplicationJob
  queue_as :default

  DISTANCE_TOLERANCE_PERCENT = 10
  DATE_TOLERANCE_DAYS = 1

  def perform(strava_activity_id)
    strava_activity = StravaActivity.find(strava_activity_id)
    user = strava_activity.user

    # Find potential matching workouts from user's plans
    potential_matches = find_matching_workouts(user, strava_activity)

    if potential_matches.any?
      # Update status to "matched" but don't link yet
      best_match = potential_matches.first
      strava_activity.update(
        match_status: "matched",
        activity: best_match
      )
      Rails.logger.info "Found match for Strava activity #{strava_activity.strava_id}: #{best_match.id}"
    else
      # Mark as unmatched so user can review
      strava_activity.update(match_status: "unmatched")
      Rails.logger.info "No matches found for Strava activity #{strava_activity.strava_id}"
    end
  end

  private

  def find_matching_workouts(user, strava_activity)
    # Get all activities from user's plans
    user_plan_activities = Activity.joins(:plan)
                                    .where(plans: { user_id: user.id })
                                    .where("start_date_local IS NOT NULL")

    matches = []

    user_plan_activities.find_each do |activity|
      score = calculate_match_score(activity, strava_activity)
      matches << { activity: activity, score: score } if score >= 0.6  # 60% threshold
    end

    # Sort by score descending and return just the activities
    matches.sort_by { |m| -m[:score] }.map { |m| m[:activity] }
  end

  def calculate_match_score(planned_activity, strava_activity)
    score = 0.0

    # Date matching (±1 day tolerance) - 40% weight
    date_score = calculate_date_score(planned_activity, strava_activity)
    score += date_score * 0.4

    # Distance matching (±10% tolerance) - 35% weight
    distance_score = calculate_distance_score(planned_activity, strava_activity)
    score += distance_score * 0.35

    # Activity type matching - 15% weight
    type_score = planned_activity.activity_type == strava_activity.activity_type ? 1.0 : 0.0
    score += type_score * 0.15

    # Description similarity - 10% weight
    description_score = calculate_description_similarity(planned_activity, strava_activity)
    score += description_score * 0.1

    score
  end

  def calculate_date_score(planned_activity, strava_activity)
    planned_date = planned_activity.start_date_local&.to_date
    strava_date = strava_activity.start_date_local&.to_date

    return 0.0 if planned_date.nil? || strava_date.nil?

    days_diff = (planned_date - strava_date).abs
    return 0.0 if days_diff > DATE_TOLERANCE_DAYS

    1.0 - (days_diff.to_f / DATE_TOLERANCE_DAYS)
  end

  def calculate_distance_score(planned_activity, strava_activity)
    return 0.0 if planned_activity.distance.nil? || strava_activity.distance.nil?

    planned_distance = planned_activity.distance
    strava_distance = strava_activity.distance

    tolerance = planned_distance * (DISTANCE_TOLERANCE_PERCENT / 100.0)
    distance_diff = (planned_distance - strava_distance).abs

    return 0.0 if distance_diff > tolerance

    1.0 - (distance_diff / tolerance)
  end

  def calculate_description_similarity(planned_activity, strava_activity)
    planned_desc = (planned_activity.description || "").downcase.strip
    strava_desc = (strava_activity.webhook_payload&.dig("description") || "").downcase.strip

    return 0.0 if planned_desc.empty? && strava_desc.empty?
    return 0.0 if planned_desc.empty? || strava_desc.empty?

    # Simple word overlap scoring
    planned_words = planned_desc.split(/\s+/)
    strava_words = strava_desc.split(/\s+/)

    common_words = (planned_words & strava_words).length
    total_words = (planned_words | strava_words).length

    common_words.to_f / total_words
  end
end
