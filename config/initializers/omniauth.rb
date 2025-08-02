require Rails.root.join("lib", "omniauth", "strategies", "strava")
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :strava,
          Rails.application.credentials.dig(:strava, :client_id),
          Rails.application.credentials.dig(:strava, :client_secret),
          scope: "read_all"
end
