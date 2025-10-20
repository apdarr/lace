class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :strava_activities, dependent: :destroy
  has_many :activities, dependent: :destroy

  def self.find_or_create_from_strava(auth)
    user = find_by(strava_id: auth.uid)

    if user
      # Update only the authentication-related tokens that might have changed
      user.update(
        access_token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token,
        token_expires_at: Time.at(auth.credentials.expires_at)
      )
    else
      # Create new user with all attributes
      user = create(
        strava_id: auth.uid,
        email_address: auth.info.email,
        firstname: auth.info.first_name,
        lastname: auth.info.last_name,
        profile_picture_url: auth.info.profile,
        access_token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token,
        token_expires_at: Time.at(auth.credentials.expires_at)
      )
    end

    user
  end
end
