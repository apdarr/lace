class DeleteStravaWebhookJob < ApplicationJob
  queue_as :default

  class SubscriptionError < StandardError; end

  def perform(user_id)
    user = User.find(user_id)

    return unless user.strava_webhook_subscription_id.present?

    subscription_id = user.strava_webhook_subscription_id

    # Use strava-ruby-client gem to delete subscription
    client = build_webhooks_client
    client.delete_push_subscription(subscription_id)

    # Clear subscription ID from user
    user.update!(strava_webhook_subscription_id: nil)
    Rails.logger.info "Strava webhook subscription deleted: #{subscription_id}"
  rescue Faraday::ResourceNotFound => e
    # Handle case where subscription was already deleted on Strava side
    user.update!(strava_webhook_subscription_id: nil)
    Rails.logger.info "Strava webhook subscription already deleted or not found: #{subscription_id}"
  rescue Strava::Errors::Fault => e
    error_message = "Failed to delete Strava webhook subscription: #{e.message}"
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
end
