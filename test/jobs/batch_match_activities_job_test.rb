require "test_helper"

class BatchMatchActivitiesJobTest < ActiveJob::TestCase
  def setup
    @plan = Plan.create!(
      length: 12,
      race_date: 3.months.from_now
    )
  end

  test "matches all unmatched activities to workouts" do
    workout1 = create_workout(distance: 5000.0, date: Date.today)
    workout2 = create_workout(distance: 8000.0, date: Date.today + 1.day)
    
    activity1 = create_activity(distance: 5000.0, date: Date.today)
    activity2 = create_activity(distance: 8000.0, date: Date.today + 1.day)
    create_activity(distance: 3000.0, date: Date.today + 10.days) # Won't match

    result = BatchMatchActivitiesJob.perform_now

    assert_equal 2, result[:matched]
    assert_equal 1, result[:unmatched]
    
    activity1.reload
    activity2.reload
    
    assert_equal workout1.id, activity1.matched_workout_id
    assert_equal workout2.id, activity2.matched_workout_id
  end

  test "matches only activities to workouts in specified plan when plan_id provided" do
    plan2 = Plan.create!(length: 12, race_date: 3.months.from_now)
    
    workout1 = create_workout(distance: 5000.0, date: Date.today, plan_id: @plan.id)
    workout2 = create_workout(distance: 5000.0, date: Date.today, plan_id: plan2.id)
    
    # Create unmatched Strava activities (they don't belong to any plan)
    activity1 = create_activity(distance: 5000.0, date: Date.today, strava_id: 1001)
    activity2 = create_activity(distance: 5000.0, date: Date.today, strava_id: 1002)

    # When we specify plan_id, it should only match to workouts in that plan
    result = BatchMatchActivitiesJob.perform_now(@plan.id)

    activity1.reload
    activity2.reload
    
    # One activity should match to workout1, the other won't match since we restricted to @plan
    matched_activities = [activity1, activity2].select { |a| a.matched_workout_id.present? }
    assert_equal 1, matched_activities.count
    assert_equal workout1.id, matched_activities.first.matched_workout_id
  end

  test "returns zero counts when no activities to match" do
    result = BatchMatchActivitiesJob.perform_now

    assert_equal 0, result[:matched]
    assert_equal 0, result[:unmatched]
  end

  test "skips already matched activities" do
    workout = create_workout(distance: 5000.0, date: Date.today)
    
    activity1 = create_activity(distance: 5000.0, date: Date.today, strava_id: 1001)
    activity1.update!(matched_workout_id: workout.id, match_confidence: 0.9)
    
    activity2 = create_activity(distance: 5000.0, date: Date.today + 1.day, strava_id: 1002)

    result = BatchMatchActivitiesJob.perform_now

    assert_equal 0, result[:matched]
    assert_equal 1, result[:unmatched]
  end

  private

  def create_workout(distance:, date:, plan_id: nil)
    Activity.create!(
      plan_id: plan_id || @plan.id,
      distance: distance,
      description: "Workout",
      start_date_local: date.to_time
    )
  end

  def create_activity(distance:, date:, strava_id: nil, plan_id: nil)
    Activity.create!(
      strava_id: strava_id || rand(1000000..9999999),
      distance: distance,
      description: "Activity",
      start_date_local: date.to_time,
      plan_id: plan_id
    )
  end
end
