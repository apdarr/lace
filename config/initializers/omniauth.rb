require Rails.root.join("lib", "omniauth", "strategies", "strava")
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :strava,
          Rails.application.credentials.dig(:strava, :client_id),
          Rails.application.credentials.dig(:strava, :client_secret),
          scope: "read,activity:read_all"

  provider :google_oauth2,
          Rails.application.credentials.dig(:google, :client_id),
          Rails.application.credentials.dig(:google, :client_secret),
          scope: "email,profile,openid",
          prompt: "select_account",
          image_aspect_ratio: "square",
          image_size: 50
end
