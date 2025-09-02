class Plan < ApplicationRecord
  # after_create :load_from_plan_template
  after_create :process_uploaded_photos

  enum :plan_type, { template: 0, custom: 1 }

  has_many_attached :photos

  validates :length, presence: true, numericality: { greater_than: 0 }
  validates :race_date, presence: true
  validate :race_date_in_future
  validate :photos_are_images, if: -> { photos.attached? }

  private

  def race_date_in_future
    return unless race_date.present?

    errors.add(:race_date, "must be in the future") if race_date <= Date.current
  end

  def photos_are_images
    photos.each do |photo|
      unless photo.content_type.in?(%w[image/jpeg image/jpg image/png image/gif])
        errors.add(:photos, "must be JPEG, PNG, or GIF images")
      end
    end
  end

  private

  def load_from_plan_template
    return unless template?
    puts "load_from_plan_template called⭐"
    start_date = (self.race_date - self.length.weeks).beginning_of_week(:monday)
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

  def process_uploaded_photos
    # Note that right now this is being called for all after_create calls
    return unless photos.attached?
    PlanPhotoProcessorJob.perform_later(self)
  end
end
