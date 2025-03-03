require Rails.root.join("lib", "omniauth", "strategies", "strava")

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :strava,
          ENV["STRAVA_CLIENT_ID"],
          ENV["STRAVA_CLIENT_SECRET"],
          scope: "read_all"
end
