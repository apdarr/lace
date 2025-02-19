require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Strava < OmniAuth::Strategies::OAuth2
      option :name, "strava"

      option :client_options, {
        site: "https://www.strava.com",
        authorize_url: "/oauth/authorize",
        token_url: "/oauth/token"
      }

      uid { raw_info["id"] }

      info do
        {
          email: raw_info["email"],
          first_name: raw_info["firstname"],
          last_name: raw_info["lastname"],
          profile: raw_info["profile"]
        }
      end

      def raw_info
        @raw_info ||= access_token.get("/api/v3/athlete").parsed
      end
    end
  end
end
