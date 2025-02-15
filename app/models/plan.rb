class Plan < ApplicationRecord
  after_create :load_from_plan_template

  private

  def load_from_plan_template
    puts "load_from_plan_template called⭐"
    start_date = (self.race_date - 17.weeks).beginning_of_week(:monday)
    template_path = Rails.root.join("app/models/templates/training_plans.yml")
    template = YAML.safe_load(File.read(template_path))
    hash = template.dig(template.first[0])

    hash.each do |week|
      week_name, week_data = week
      week_data.each do |day_name, planned_activity|
        Activity.create(
          plan_id: self.id,
          distance: planned_activity["distance"].to_f,
          description: planned_activity["description"],
          start_date_local: start_date)
        start_date += 1.day
      end
    end
  end
end
