require "strava/webhooks/client"

# Below we load in the Strava Webhooks Client from the strava-ruby-client gem, and perform a few cleanup tasks using the configured client

class StravaWebhookService
  class SubscriptionError < StandardError; end

  # Register a webhook subscription with Strava
  # Automatically deletes any existing subscription first (Strava only allows one per app)
  def self.create_subscription(user, callback_url)
    # First, delete any existing subscription for the application
    # TODO create an integration test that walks through creating a new test subscription, with a VCR cassette, and validates creds
    delete_existing_subscription

    RegisterStravaWebhookJob.perform_now(user.id, callback_url)
  end

  # Delete a webhook subscription from Strava (queues a background job)
  def self.delete_subscription(user)
    DeleteStravaWebhookJob.perform_now(user.id)
  end

  # Delete any existing subscription for the application (Strava only allows one per app)
  def self.delete_existing_subscription
    client = build_webhooks_client
    subscriptions = client.push_subscriptions

    subscriptions.each do |sub|
      Rails.logger.info "Deleting existing Strava webhook subscription: #{sub.id}"
      client.delete_push_subscription(sub.id)
    end
  rescue Strava::Errors::Fault => e
    Rails.logger.warn "Could not clean up existing subscriptions: #{e.message}"
    # Continue anyway - the create will fail if there's still a subscription
  end

  private

  def self.build_webhooks_client
    Strava::Webhooks::Client.new(
      client_id: Rails.application.credentials.dig(:strava, :client_id),
      client_secret: Rails.application.credentials.dig(:strava, :client_secret)
    )
  end
end
