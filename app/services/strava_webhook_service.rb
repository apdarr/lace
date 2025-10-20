require "net/http"
require "uri"
require "json"

class StravaWebhookService
  class SubscriptionError < StandardError; end

  # Register a webhook subscription with Strava for a user
  def self.create_subscription(user, callback_url)
    client_id = Rails.application.credentials.dig(:strava, :client_id)
    client_secret = Rails.application.credentials.dig(:strava, :client_secret)
    verify_token = webhook_verify_token

    # Store the verify token for this user
    user.update!(webhook_verify_token: verify_token)

    # Make API call to Strava to create subscription
    uri = URI("https://www.strava.com/api/v3/push_subscriptions")
    response = Net::HTTP.post_form(uri, {
      client_id: client_id,
      client_secret: client_secret,
      callback_url: callback_url,
      verify_token: verify_token
    })

    if response.is_a?(Net::HTTPSuccess)
      subscription_data = JSON.parse(response.body)
      subscription_id = subscription_data["id"].to_s

      # Store subscription ID on user
      user.update!(strava_webhook_subscription_id: subscription_id)

      Rails.logger.info "Strava webhook subscription created: #{subscription_id}"
      subscription_id
    else
      error_message = "Failed to create Strava webhook subscription: #{response.code} - #{response.body}"
      Rails.logger.error error_message
      raise SubscriptionError, error_message
    end
  end

  # Delete a webhook subscription from Strava
  def self.delete_subscription(user)
    return unless user.strava_webhook_subscription_id.present?

    client_id = Rails.application.credentials.dig(:strava, :client_id)
    client_secret = Rails.application.credentials.dig(:strava, :client_secret)
    subscription_id = user.strava_webhook_subscription_id

    uri = URI("https://www.strava.com/api/v3/push_subscriptions/#{subscription_id}")
    uri.query = URI.encode_www_form({
      client_id: client_id,
      client_secret: client_secret
    })

    request = Net::HTTP::Delete.new(uri)
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess) || response.code == "404"
      # Clear subscription ID from user (404 means it's already deleted)
      user.update!(strava_webhook_subscription_id: nil)
      Rails.logger.info "Strava webhook subscription deleted: #{subscription_id}"
      true
    else
      error_message = "Failed to delete Strava webhook subscription: #{response.code} - #{response.body}"
      Rails.logger.error error_message
      raise SubscriptionError, error_message
    end
  end

  # List all webhook subscriptions (for debugging/management)
  def self.list_subscriptions
    client_id = Rails.application.credentials.dig(:strava, :client_id)
    client_secret = Rails.application.credentials.dig(:strava, :client_secret)

    uri = URI("https://www.strava.com/api/v3/push_subscriptions")
    uri.query = URI.encode_www_form({
      client_id: client_id,
      client_secret: client_secret
    })

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      error_message = "Failed to list Strava webhook subscriptions: #{response.code} - #{response.body}"
      Rails.logger.error error_message
      raise SubscriptionError, error_message
    end
  end

  # View details of a specific subscription
  def self.view_subscription(subscription_id)
    client_id = Rails.application.credentials.dig(:strava, :client_id)
    client_secret = Rails.application.credentials.dig(:strava, :client_secret)

    uri = URI("https://www.strava.com/api/v3/push_subscriptions/#{subscription_id}")
    uri.query = URI.encode_www_form({
      client_id: client_id,
      client_secret: client_secret
    })

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      error_message = "Failed to view Strava webhook subscription: #{response.code} - #{response.body}"
      Rails.logger.error error_message
      raise SubscriptionError, error_message
    end
  end

  private

  def self.webhook_verify_token
    ENV["STRAVA_WEBHOOK_VERIFY_TOKEN"] || Rails.application.credentials.dig(:strava, :webhook_verify_token) || "lace_strava_webhook"
  end
end
