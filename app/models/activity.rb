class Activity < ApplicationRecord
  has_neighbors :embedding

  belongs_to :plan, optional: true
  belongs_to :matched_workout, class_name: "Activity", optional: true
  has_many :matched_activities, class_name: "Activity", foreign_key: :matched_workout_id, dependent: :nullify

  # Validations
  validates :matched_workout_id, exclusion: { in: ->(activity) { [activity.id] } }, if: :matched_workout_id?
  validate :matched_workout_must_be_planned_workout, if: :matched_workout_id?
  validate :cannot_match_strava_activity_to_another_strava_activity, if: :matched_workout_id?

  # Scopes
  scope :planned_workouts, -> { where.not(plan_id: nil).where(strava_id: nil) }
  scope :strava_activities, -> { where.not(strava_id: nil) }
  scope :matched, -> { where.not(matched_workout_id: nil) }
  scope :unmatched, -> { where(matched_workout_id: nil).where.not(strava_id: nil) }

  # Check if this is a planned workout (not a Strava activity)
  def planned_workout?
    strava_id.nil? && plan_id.present?
  end

  # Check if this is a Strava activity
  def strava_activity?
    strava_id.present?
  end

  # Check if this activity is matched to a workout
  def matched?
    matched_workout_id.present?
  end

  private

  def matched_workout_must_be_planned_workout
    return unless matched_workout

    unless matched_workout.planned_workout?
      errors.add(:matched_workout_id, "must be a planned workout, not a Strava activity")
    end
  end

  def cannot_match_strava_activity_to_another_strava_activity
    return unless strava_activity? && matched_workout

    if matched_workout.strava_activity?
      errors.add(:matched_workout_id, "cannot match a Strava activity to another Strava activity")
    end
  end
end
