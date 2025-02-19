class User < ApplicationRecord
  has_many :sessions, dependent: :destroy

  def self.find_or_create_from_strava(auth)
    user = find_by(strava_id: auth.uid) || new(strava_id: auth.uid)
    user.email_address = auth.info.email
    user.firstname = auth.info.first_name
    user.lastname = auth.info.last_name
    user.profile_picture_url = auth.info.profile
    user.access_token = auth.credentials.token
    user.refresh_token = auth.credentials.refresh_token
    user.token_expires_at = Time.at(auth.credentials.expires_at)

    user.save
    user
  end
end
