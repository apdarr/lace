class Activity < ApplicationRecord
  has_neighbors :embedding

  belongs_to :plan, optional: true
  belongs_to :user, optional: true
  has_many :strava_activities, dependent: :destroy

  # Returns the first matched or linked StravaActivity, if any
  def matched_strava_activity
    strava_activities.where(match_status: %w[matched linked]).first
  end
end
