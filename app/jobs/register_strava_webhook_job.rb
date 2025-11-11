class RegisterStravaWebhookJob < ApplicationJob
  queue_as :default

  class SubscriptionError < StandardError; end

  def perform(user_id, callback_url)
    user = User.find(user_id)

    verify_token = webhook_verify_token

    # Store the verify token for this user
    user.update!(webhook_verify_token: verify_token)

    # Use strava-ruby-client gem to create subscription
    client = build_webhooks_client
    subscription = client.create_push_subscription(callback_url: callback_url, verify_token: verify_token)

    # Store subscription ID on user
    user.update!(strava_webhook_subscription_id: subscription.id.to_s)

    Rails.logger.info "Strava webhook subscription created: #{subscription.id}"
  rescue Strava::Errors::Fault => e
    error_message = "Failed to create Strava webhook subscription: #{e.message}"
    Rails.logger.error error_message
    raise SubscriptionError, error_message
  end

  private

  def build_webhooks_client
    Strava::Webhooks::Client.new(
      client_id: ENV["STRAVA_CLIENT_ID"].presence || Rails.application.credentials.dig(:strava, :client_id),
      client_secret: ENV["STRAVA_CLIENT_SECRET"].presence || Rails.application.credentials.dig(:strava, :client_secret)
    )
  end

  def webhook_verify_token
    ENV["STRAVA_WEBHOOK_VERIFY_TOKEN"] || Rails.application.credentials.dig(:strava, :webhook_verify_token) || "lace_strava_webhook"
  end
end
