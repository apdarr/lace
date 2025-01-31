class Activity < ApplicationRecord
  has_neighbors :embedding

  def self.load_from_plan_template(plan)
    # Maybe extract this as a before_save action on Plan model before it saves?
    start_date = (plan.race_date - 17.weeks).beginning_of_week(:monday)

    template_path = Rails.root.join("app/models/templates/training_plans.yml")
    template = YAML.load_file(template_path)
    hash = template.dig(template.first[0])
    # Start with the week
    hash.each do |week|
      week_name, week_data = week
      # For each week, iterate over the days
      week_data.each do |day_name, planned_activity|
        # For each day, iterate over the planned activity hash
        Activity.create(
          distance: planned_activity["distance"].to_f,
          description: planned_activity["description"],
          start_date_local: start_date)
        start_date += 1.day
      end
    end
  end
end
