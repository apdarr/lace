require Rails.root.join("lib", "omniauth", "strategies", "strava")
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :strava,
          ENV["STRAVA_CLIENT_ID"].presence || Rails.application.credentials.dig(:strava, :client_id),
          ENV["STRAVA_CLIENT_SECRET"].presence || Rails.application.credentials.dig(:strava, :client_secret),
          scope: "read_all"
end
