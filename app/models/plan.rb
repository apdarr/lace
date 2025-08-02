class Plan < ApplicationRecord
  has_many_attached :photos
  
  after_create :load_from_plan_template

  def process_uploaded_photos
    return [] unless photos.attached?
    
    parsed_workouts = []
    photos.each do |photo|
      photo.open do |file|
        parser = TrainingPlanImageParser.new(file.path)
        result = parser.parse_workouts
        parsed_workouts << result unless result[:error]
      end
    end
    
    parsed_workouts
  end

  def create_activities_from_parsed_data(parsed_workouts)
    return if parsed_workouts.empty?
    
    start_date = (race_date - (length || 18).weeks).beginning_of_week(:monday)
    
    parsed_workouts.each do |workout_data|
      workout_data["weeks"].each_with_index do |week_data, week_index|
        week_start = start_date + (week_index * 7).days
        
        %w[monday tuesday wednesday thursday friday saturday sunday].each_with_index do |day, day_index|
          workout = week_data["workouts"][day]
          next unless workout
          
          Activity.create!(
            plan_id: id,
            distance: workout["distance"].to_f,
            description: workout["description"],
            start_date_local: week_start + day_index.days
          )
        end
      end
    end
  end

  private

  def load_from_plan_template
    # Only load from template if this is not a custom creation
    return if custom_creation?
    
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
