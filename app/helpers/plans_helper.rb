module PlansHelper
  def calculate_week_total_miles(activities, week_start)
    week_end = week_start + 6.days
    weekly_activities = activities.select { |date, activity| date >= week_start && date <= week_end }
    weekly_activities.values.sum { |activity| activity.distance || 0 }
  end
end
