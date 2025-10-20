require "test_helper"

class ActivityMatcherTest < ActiveSupport::TestCase
  def setup
    @plan = Plan.create!(
      length: 12,
      race_date: 3.months.from_now
    )
  end

  test "find_best_match returns nil for non-strava activities" do
    workout = create_workout(distance: 5000.0, date: Date.today)
    matcher = ActivityMatcher.new(workout)
    
    assert_nil matcher.find_best_match
  end

  test "find_best_match returns nil for already matched activities" do
    workout = create_workout(distance: 5000.0, date: Date.today)
    activity = create_activity(
      distance: 5000.0,
      date: Date.today,
      matched_workout_id: workout.id
    )
    matcher = ActivityMatcher.new(activity)
    
    assert_nil matcher.find_best_match
  end

  test "find_best_match returns workout with high confidence for exact match" do
    workout = create_workout(distance: 5000.0, date: Date.today)
    activity = create_activity(distance: 5000.0, date: Date.today)
    matcher = ActivityMatcher.new(activity)
    
    result = matcher.find_best_match
    assert_not_nil result
    assert_equal workout.id, result[:workout].id
    assert result[:confidence] > 0.7
  end

  test "find_best_match returns workout for date within tolerance" do
    workout = create_workout(distance: 5000.0, date: Date.today)
    activity = create_activity(distance: 5000.0, date: Date.today + 1.day)
    matcher = ActivityMatcher.new(activity)
    
    result = matcher.find_best_match
    assert_not_nil result
    assert_equal workout.id, result[:workout].id
  end

  test "find_best_match returns nil for date outside tolerance" do
    workout = create_workout(distance: 5000.0, date: Date.today)
    activity = create_activity(distance: 5000.0, date: Date.today + 3.days)
    matcher = ActivityMatcher.new(activity)
    
    result = matcher.find_best_match
    assert_nil result
  end

  test "find_best_match returns workout for distance within 10% tolerance" do
    workout = create_workout(distance: 5000.0, date: Date.today)
    # 5% over - should still match
    activity = create_activity(distance: 5250.0, date: Date.today)
    matcher = ActivityMatcher.new(activity)
    
    result = matcher.find_best_match
    assert_not_nil result
    assert_equal workout.id, result[:workout].id
  end

  test "find_best_match confidence decreases with distance variance" do
    workout = create_workout(distance: 5000.0, date: Date.today)
    
    # Exact match
    activity1 = create_activity(distance: 5000.0, date: Date.today, strava_id: 1001)
    matcher1 = ActivityMatcher.new(activity1)
    result1 = matcher1.find_best_match
    
    # 5% off
    activity2 = create_activity(distance: 5250.0, date: Date.today, strava_id: 1002)
    matcher2 = ActivityMatcher.new(activity2)
    result2 = matcher2.find_best_match
    
    assert result1[:confidence] > result2[:confidence]
  end

  test "find_best_match returns nil when no workout in date range" do
    create_workout(distance: 5000.0, date: Date.today - 5.days)
    activity = create_activity(distance: 5000.0, date: Date.today)
    matcher = ActivityMatcher.new(activity)
    
    result = matcher.find_best_match
    assert_nil result
  end

  test "find_best_match prefers closer date when multiple candidates" do
    workout1 = create_workout(distance: 5000.0, date: Date.today, description: "Run 1")
    workout2 = create_workout(distance: 5000.0, date: Date.today + 1.day, description: "Run 2")
    activity = create_activity(distance: 5000.0, date: Date.today)
    matcher = ActivityMatcher.new(activity)
    
    result = matcher.find_best_match
    assert_equal workout1.id, result[:workout].id
  end

  test "find_best_match does not return already matched workouts" do
    workout1 = create_workout(distance: 5000.0, date: Date.today, description: "Run 1")
    workout2 = create_workout(distance: 5000.0, date: Date.today, description: "Run 2")
    
    # Match workout1 to another activity
    other_activity = create_activity(distance: 5000.0, date: Date.today, strava_id: 999)
    other_activity.update!(matched_workout_id: workout1.id)
    
    # New activity should match to workout2, not workout1
    activity = create_activity(distance: 5000.0, date: Date.today, strava_id: 1000)
    matcher = ActivityMatcher.new(activity)
    
    result = matcher.find_best_match
    assert_equal workout2.id, result[:workout].id
  end

  test "match! saves matched workout and confidence" do
    workout = create_workout(distance: 5000.0, date: Date.today)
    activity = create_activity(distance: 5000.0, date: Date.today)
    matcher = ActivityMatcher.new(activity)
    
    assert matcher.match!
    activity.reload
    
    assert_equal workout.id, activity.matched_workout_id
    assert activity.match_confidence > 0
    assert_not_nil activity.matched_at
  end

  test "match! returns false when no match found" do
    create_workout(distance: 5000.0, date: Date.today - 5.days)
    activity = create_activity(distance: 5000.0, date: Date.today)
    matcher = ActivityMatcher.new(activity)
    
    assert_equal false, matcher.match!
  end

  test "activity type similarity increases confidence" do
    workout = create_workout(
      distance: 5000.0,
      date: Date.today,
      activity_type: "Run"
    )
    
    activity1 = create_activity(
      distance: 5000.0,
      date: Date.today,
      activity_type: "Run",
      strava_id: 1001
    )
    matcher1 = ActivityMatcher.new(activity1)
    result1 = matcher1.find_best_match
    
    activity2 = create_activity(
      distance: 5000.0,
      date: Date.today,
      activity_type: "Ride",
      strava_id: 1002
    )
    matcher2 = ActivityMatcher.new(activity2)
    result2 = matcher2.find_best_match
    
    # Run-to-Run should have higher confidence than Run-to-Ride
    assert result1[:confidence] > result2[:confidence]
  end

  test "description similarity increases confidence" do
    workout = create_workout(
      distance: 5000.0,
      date: Date.today,
      description: "Easy run in the morning"
    )
    
    activity1 = create_activity(
      distance: 5000.0,
      date: Date.today,
      description: "Easy run",
      strava_id: 1001
    )
    matcher1 = ActivityMatcher.new(activity1)
    result1 = matcher1.find_best_match
    
    activity2 = create_activity(
      distance: 5000.0,
      date: Date.today,
      description: "Random activity",
      strava_id: 1002
    )
    matcher2 = ActivityMatcher.new(activity2)
    result2 = matcher2.find_best_match
    
    # Matching description should have higher confidence
    assert result1[:confidence] > result2[:confidence]
  end

  test "unmatch! removes matched workout from activity" do
    workout = create_workout(distance: 5000.0, date: Date.today)
    activity = create_activity(distance: 5000.0, date: Date.today)
    matcher = ActivityMatcher.new(activity)
    
    matcher.match!
    activity.reload
    assert activity.matched?
    
    matcher.unmatch!
    activity.reload
    
    assert_nil activity.matched_workout_id
    assert_nil activity.match_confidence
    assert_nil activity.matched_at
  end

  test "unmatch! returns false when activity is not matched" do
    activity = create_activity(distance: 5000.0, date: Date.today)
    matcher = ActivityMatcher.new(activity)
    
    assert_equal false, matcher.unmatch!
  end

  private

  def create_workout(distance:, date:, description: "Workout", activity_type: "Run")
    Activity.create!(
      plan_id: @plan.id,
      distance: distance,
      description: description,
      activity_type: activity_type,
      start_date_local: date.to_time
    )
  end

  def create_activity(distance:, date:, strava_id: nil, description: "Activity", activity_type: "Run", matched_workout_id: nil)
    Activity.create!(
      strava_id: strava_id || rand(1000000..9999999),
      distance: distance,
      description: description,
      activity_type: activity_type,
      start_date_local: date.to_time,
      matched_workout_id: matched_workout_id
    )
  end
end
