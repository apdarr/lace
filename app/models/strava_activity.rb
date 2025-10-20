class StravaActivity < ApplicationRecord
  belongs_to :user
  belongs_to :activity, optional: true

  enum :match_status, { unmatched: "unmatched", matched: "matched", linked: "linked" }, validate: true

  validates :strava_id, presence: true, uniqueness: { scope: :user_id }
  validates :strava_athlete_id, presence: true
  validates :user_id, presence: true

  scope :unmatched, -> { where(match_status: "unmatched") }
  scope :matched, -> { where(match_status: "matched") }
  scope :linked, -> { where(match_status: "linked") }
end
