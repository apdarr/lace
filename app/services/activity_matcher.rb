# Service for matching Strava activities to planned workouts
#
# This service implements an intelligent matching algorithm that attempts to link
# newly imported Strava activities to planned workouts in a user's training plan.
#
# Matching Algorithm:
# - Date matching: ±1 day tolerance (40% weight)
# - Distance matching: ±10% tolerance (40% weight)
# - Activity type matching: Exact or partial match (10% weight)
# - Description similarity: Keyword matching (10% weight)
#
# Usage:
#   matcher = ActivityMatcher.new(strava_activity)
#   result = matcher.find_best_match
#   # => { workout: Activity, confidence: 0.85 } or nil
#
#   # To automatically match and save:
#   matcher.match!  # => true if matched, false otherwise
#
#   # To unmatch an activity:
#   matcher.unmatch!  # => true if unmatched, false otherwise
#
# The confidence score ranges from 0.0 to 1.0, with matches below
# MIN_CONFIDENCE_THRESHOLD (0.3) being rejected.
class ActivityMatcher
  # Match tolerance constants
  DATE_TOLERANCE_DAYS = 1
  DISTANCE_TOLERANCE_PERCENT = 0.10
  MIN_CONFIDENCE_THRESHOLD = 0.3

  def initialize(activity)
    @activity = activity
  end

  # Find the best matching workout for this activity
  # Returns a hash with { workout: Activity, confidence: Float } or nil if no match found
  def find_best_match
    return nil unless @activity.strava_activity?
    return nil if @activity.matched?

    candidate_workouts = find_candidate_workouts
    return nil if candidate_workouts.empty?

    scored_workouts = score_workouts(candidate_workouts)
    best_match = scored_workouts.max_by { |w| w[:confidence] }

    # Only return matches above threshold
    best_match if best_match && best_match[:confidence] >= MIN_CONFIDENCE_THRESHOLD
  end

  # Match the activity to a workout and save the match
  def match!
    best_match = find_best_match
    return false unless best_match

    @activity.update!(
      matched_workout_id: best_match[:workout].id,
      match_confidence: best_match[:confidence],
      matched_at: Time.current
    )

    true
  end

  # Unmatch the activity from its current workout
  def unmatch!
    return false unless @activity.matched?

    @activity.update!(
      matched_workout_id: nil,
      match_confidence: nil,
      matched_at: nil
    )

    true
  end

  private

  # Find workouts that could potentially match this activity
  def find_candidate_workouts
    return [] unless @activity.start_date_local.present?

    # Look for planned workouts within date range
    start_date = @activity.start_date_local.to_date - DATE_TOLERANCE_DAYS.days
    end_date = @activity.start_date_local.to_date + DATE_TOLERANCE_DAYS.days

    # Find planned workouts that haven't been matched yet
    Activity.planned_workouts
      .where(start_date_local: start_date.beginning_of_day..end_date.end_of_day)
      .where.missing(:matched_activities)
  end

  # Score each candidate workout based on multiple factors
  def score_workouts(workouts)
    workouts.map do |workout|
      {
        workout: workout,
        confidence: calculate_confidence(workout)
      }
    end
  end

  # Calculate confidence score (0.0 - 1.0) based on multiple factors
  def calculate_confidence(workout)
    scores = []

    # Date proximity (0.0 - 0.4)
    scores << date_score(workout) * 0.4

    # Distance match (0.0 - 0.4)
    scores << distance_score(workout) * 0.4

    # Activity type match (0.0 - 0.1)
    scores << activity_type_score(workout) * 0.1

    # Description similarity (0.0 - 0.1)
    scores << description_score(workout) * 0.1

    scores.sum
  end

  # Score based on date proximity (1.0 = same day, 0.5 = 1 day off)
  def date_score(workout)
    return 0.0 unless @activity.start_date_local.present? && workout.start_date_local.present?

    days_diff = (@activity.start_date_local.to_date - workout.start_date_local.to_date).abs
    return 1.0 if days_diff == 0
    return 0.5 if days_diff == 1

    0.0
  end

  # Score based on distance match (1.0 = within tolerance, 0.0 = far off)
  def distance_score(workout)
    return 0.0 unless @activity.distance.present? && workout.distance.present?
    return 1.0 if workout.distance == 0 # Skip distance check for rest days

    # Convert activity distance from meters to miles if needed
    activity_distance = @activity.distance
    workout_distance = workout.distance

    # Calculate allowed tolerance
    tolerance = workout_distance * DISTANCE_TOLERANCE_PERCENT
    diff = (activity_distance - workout_distance).abs

    if diff <= tolerance
      # Linear scale from 1.0 (exact match) to 0.5 (at tolerance boundary)
      1.0 - (diff / tolerance) * 0.5
    else
      # Beyond tolerance, score drops quickly
      max_diff = workout_distance * 0.5
      if diff <= max_diff
        0.5 * (1.0 - (diff - tolerance) / (max_diff - tolerance))
      else
        0.0
      end
    end
  end

  # Score based on activity type match
  def activity_type_score(workout)
    return 0.5 unless @activity.activity_type.present? && workout.activity_type.present?

    # Exact match
    return 1.0 if @activity.activity_type.downcase == workout.activity_type.downcase

    # Partial match for running types
    running_types = ["run", "running", "long run", "easy run", "tempo run", "workout"]
    activity_running = running_types.any? { |type| @activity.activity_type.downcase.include?(type) }
    workout_running = running_types.any? { |type| workout.activity_type.downcase.include?(type) }

    activity_running && workout_running ? 0.7 : 0.0
  end

  # Score based on description similarity
  def description_score(workout)
    return 0.5 unless @activity.description.present? && workout.description.present?

    activity_desc = @activity.description.downcase
    workout_desc = workout.description.downcase

    # Check for common keywords
    keywords = extract_keywords(workout_desc)
    return 1.0 if keywords.empty?

    matching_keywords = keywords.count { |kw| activity_desc.include?(kw) }
    matching_keywords.to_f / keywords.size
  end

  # Extract keywords from description
  def extract_keywords(text)
    # Common running workout keywords
    keywords = %w[easy tempo interval long recovery hill fartlek speed workout]
    text.split(/\s+/).select { |word| keywords.include?(word) }
  end
end
