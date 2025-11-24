require "strava/webhooks/client"

class StravaWebhookService
  class SubscriptionError < StandardError; end

  # Register a webhook subscription with Strava (queues a background job)
  def self.create_subscription(user, callback_url)
    RegisterStravaWebhookJob.perform_later(user.id, callback_url)
  end

  # Delete a webhook subscription from Strava (queues a background job)
  def self.delete_subscription(user)
    DeleteStravaWebhookJob.perform_later(user.id)
  end

  # List all webhook subscriptions for the application
  def self.list_subscriptions
    client = build_webhooks_client
    client.push_subscriptions
  rescue Strava::Errors::Fault => e
    error_message = "Failed to list Strava webhook subscriptions: #{e.message}"
    Rails.logger.error error_message
    raise SubscriptionError, error_message
  end

  # View details of a specific subscription
  def self.view_subscription(subscription_id)
    client = build_webhooks_client
    subscriptions = client.push_subscriptions
    subscriptions.find { |s| s.id.to_s == subscription_id.to_s }
  rescue Strava::Errors::Fault => e
    error_message = "Failed to view Strava webhook subscription: #{e.message}"
    Rails.logger.error error_message
    raise SubscriptionError, error_message
  end

  private

  def self.build_webhooks_client
    Strava::Webhooks::Client.new(
      client_id: Rails.application.credentials.dig(:strava, :client_id),
      client_secret: Rails.application.credentials.dig(:strava, :client_secret)
    )
  end
end
