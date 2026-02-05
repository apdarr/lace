class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
  has_many :strava_activities, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :plans, dependent: :destroy

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

  # Returns a valid access token, refreshing if expired
  def fresh_access_token
    return access_token if token_valid?

    refresh_strava_token!
    access_token
  end

  def token_valid?
    token_expires_at.present? && token_expires_at > Time.current
  end

  def refresh_strava_token!
    client = Strava::OAuth::Client.new(
      client_id: Rails.application.credentials.dig(:strava, :client_id),
      client_secret: Rails.application.credentials.dig(:strava, :client_secret)
    )

    response = client.oauth_token(
      grant_type: "refresh_token",
      refresh_token: refresh_token
    )

    update!(
      access_token: response.access_token,
      refresh_token: response.refresh_token,
      token_expires_at: Time.at(response.expires_at)
    )

    Rails.logger.info "Refreshed Strava token for user #{id}"
  rescue StandardError => e
    Rails.logger.error "Failed to refresh Strava token for user #{id}: #{e.message}"
    raise e
  end
end
