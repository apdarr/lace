class Activity < ApplicationRecord
  has_neighbors :embedding

  belongs_to :plan, optional: true
  belongs_to :user, optional: true
  has_many :strava_activities, dependent: :destroy
end
