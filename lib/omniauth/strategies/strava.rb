require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Strava < OmniAuth::Strategies::OAuth2
      option :name, "strava"
      option :client_options, {
        site: "https://www.strava.com",
        authorize_url: "https://www.strava.com/oauth/authorize",
        token_url: "https://www.strava.com/oauth/token"
      }

      # def callback_url
      #   full_host + script_name + callback_path
      # end

      # def authorize_params
      #   super.tap do |params|
      #     params[:approval_prompt] = "auto"
      #   end
      # end

      def token_params
        super.tap do |params|
          params[:client_id] = options.client_id
          params[:client_secret] = options.client_secret
        end
      end

      # def build_access_token
      #   verifier = request.params["code"]
      #   raise "Missing code parameter" unless verifier

      #   client.auth_code.get_token(
      #     verifier,
      #     {
      #       redirect_uri: callback_url,
      #       client_id: options.client_id,
      #       client_secret: options.client_secret
      #     },
      #     deep_symbolize(options.auth_token_params)
      #   )
      # end

      uid { raw_info["id"].to_s }

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
