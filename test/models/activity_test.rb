require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  test "planned_workout? returns true for activities without strava_id and with plan_id" do
    workout = Activity.create!(
      plan_id: 1,
      distance: 5.0,
      description: "Easy run",
      start_date_local: Date.today
    )
    assert workout.planned_workout?
    refute workout.strava_activity?
  end

  test "strava_activity? returns true for activities with strava_id" do
    activity = Activity.create!(
      strava_id: 123456,
      distance: 5000.0,
      start_date_local: Time.current
    )
    assert activity.strava_activity?
    refute activity.planned_workout?
  end

  test "matched? returns true when matched_workout_id is present" do
    workout = Activity.create!(
      plan_id: 1,
      distance: 5.0,
      start_date_local: Date.today
    )
    activity = Activity.create!(
      strava_id: 123456,
      distance: 5000.0,
      matched_workout_id: workout.id,
      start_date_local: Time.current
    )
    assert activity.matched?
  end

  test "planned_workouts scope returns only activities without strava_id" do
    workout = Activity.create!(
      plan_id: 1,
      distance: 5.0,
      start_date_local: Date.today
    )
    Activity.create!(
      strava_id: 123456,
      distance: 5000.0,
      start_date_local: Time.current
    )

    workouts = Activity.planned_workouts
    assert_includes workouts, workout
    assert_equal 1, workouts.where(id: workout.id).count
  end

  test "strava_activities scope returns only activities with strava_id" do
    Activity.create!(
      plan_id: 1,
      distance: 5.0,
      start_date_local: Date.today
    )
    activity = Activity.create!(
      strava_id: 123456,
      distance: 5000.0,
      start_date_local: Time.current
    )

    strava_activities = Activity.strava_activities
    assert_includes strava_activities, activity
    assert strava_activities.all? { |a| a.strava_id.present? }
  end

  test "matched scope returns only matched activities" do
    workout = Activity.create!(
      plan_id: 1,
      distance: 5.0,
      start_date_local: Date.today
    )
    matched_activity = Activity.create!(
      strava_id: 123456,
      distance: 5000.0,
      matched_workout_id: workout.id,
      start_date_local: Time.current
    )
    Activity.create!(
      strava_id: 789012,
      distance: 3000.0,
      start_date_local: Time.current
    )

    matched = Activity.matched
    assert_includes matched, matched_activity
    assert matched.all? { |a| a.matched_workout_id.present? }
  end

  test "unmatched scope returns only unmatched strava activities" do
    workout = Activity.create!(
      plan_id: 1,
      distance: 5.0,
      start_date_local: Date.today
    )
    Activity.create!(
      strava_id: 123456,
      distance: 5000.0,
      matched_workout_id: workout.id,
      start_date_local: Time.current
    )
    unmatched_activity = Activity.create!(
      strava_id: 789012,
      distance: 3000.0,
      start_date_local: Time.current
    )

    unmatched = Activity.unmatched
    assert_includes unmatched, unmatched_activity
    assert unmatched.all? { |a| a.strava_id.present? && a.matched_workout_id.nil? }
  end

  test "matched_workout association works" do
    workout = Activity.create!(
      plan_id: 1,
      distance: 5.0,
      description: "Easy run",
      start_date_local: Date.today
    )
    activity = Activity.create!(
      strava_id: 123456,
      distance: 5000.0,
      matched_workout_id: workout.id,
      start_date_local: Time.current
    )

    assert_equal workout, activity.matched_workout
  end

  test "matched_activities association works" do
    workout = Activity.create!(
      plan_id: 1,
      distance: 5.0,
      description: "Easy run",
      start_date_local: Date.today
    )
    activity1 = Activity.create!(
      strava_id: 123456,
      distance: 5000.0,
      matched_workout_id: workout.id,
      start_date_local: Time.current
    )
    activity2 = Activity.create!(
      strava_id: 789012,
      distance: 5100.0,
      matched_workout_id: workout.id,
      start_date_local: Time.current + 1.day
    )

    assert_includes workout.matched_activities, activity1
    assert_includes workout.matched_activities, activity2
    assert_equal 2, workout.matched_activities.count
  end

  test "validates matched_workout must be a planned workout" do
    strava_activity1 = Activity.create!(
      strava_id: 123456,
      distance: 5000.0,
      start_date_local: Time.current
    )
    strava_activity2 = Activity.build(
      strava_id: 789012,
      distance: 5100.0,
      matched_workout_id: strava_activity1.id,
      start_date_local: Time.current
    )

    refute strava_activity2.valid?
    assert_includes strava_activity2.errors[:matched_workout_id], "cannot match a Strava activity to another Strava activity"
  end

  test "validates activity cannot be matched to itself" do
    activity = Activity.create!(
      strava_id: 123456,
      distance: 5000.0,
      start_date_local: Time.current
    )
    activity.matched_workout_id = activity.id

    refute activity.valid?
    assert_includes activity.errors[:matched_workout_id], "is reserved"
  end

  test "planned workout can have multiple matched activities" do
    workout = Activity.create!(
      plan_id: 1,
      distance: 5.0,
      start_date_local: Date.today
    )
    
    activity1 = Activity.create!(
      strava_id: 123456,
      distance: 5000.0,
      matched_workout_id: workout.id,
      start_date_local: Time.current
    )
    
    activity2 = Activity.create!(
      strava_id: 789012,
      distance: 5000.0,
      matched_workout_id: workout.id,
      start_date_local: Time.current
    )

    assert activity1.valid?
    assert activity2.valid?
    assert_equal 2, workout.matched_activities.count
  end
end
