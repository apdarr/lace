class Plan < ApplicationRecord
  after_create :process_uploaded_photos

  enum :plan_type, { template: "template", custom: "custom" }
  enum :processing_status, { idle: "idle", queued: "queued", processing: "processing", completed: "completed", failed: "failed" }

  has_many :activities, dependent: :destroy
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
      unless photo.content_type.in?(%w[image/jpeg image/jpg image/png image/gif image/heic image/heif])
        errors.add(:photos, "must be JPEG, PNG, GIF, or HEIC images")
      end
    end
  end

  private

  def process_uploaded_photos
    # Note that right now this is being called for all after_create calls
    return unless photos.attached?

    job = PlanPhotoProcessorJob.perform_later(self)
    update!(processing_status: "queued", job_id: job.job_id)
  end
end
