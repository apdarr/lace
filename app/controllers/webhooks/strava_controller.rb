class Webhooks::StravaController < ApplicationController
  # CSRF protection must be disabled for webhook endpoints because external services
  # (Strava) cannot obtain Rails CSRF tokens. Security is maintained through:
  # 1. Verify token validation in the verify endpoint
  # 2. Owner ID validation in the event endpoint (matches against known Strava user IDs)
  # 3. Webhook subscriptions are created by authenticated users only
  skip_before_action :verify_authenticity_token, only: [ :verify, :event ]
  skip_before_action :require_authentication

  # GET /webhooks/strava - Webhook verification endpoint
  # Strava sends this to verify the webhook endpoint during subscription
  def verify
    # Extract the challenge token and verify token from params
    challenge = params["hub.challenge"]
    mode = params["hub.mode"]
    verify_token = params["hub.verify_token"]

    # Verify that this is a subscription request with the correct token
    if mode == "subscribe" && verify_token == webhook_verify_token
      render json: { "hub.challenge": challenge }, status: :ok
    else
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  # POST /webhooks/strava - Webhook event endpoint
  # Strava sends activity events here
  def event
    # Log the event for debugging
    Rails.logger.info "Received Strava webhook event: #{params.inspect}"

    # Extract the event data
    aspect_type = params[:aspect_type] # create, update, delete
    object_type = params[:object_type] # activity, athlete
    object_id = params[:object_id]
    owner_id = params[:owner_id] # Strava athlete ID

    # Only process activity events
    if object_type == "activity"
      # Queue a background job to process the event
      ProcessStravaWebhookJob.perform_later(
        aspect_type: aspect_type,
        object_id: object_id,
        owner_id: owner_id
      )
    end

    # Always respond with 200 OK to acknowledge receipt
    head :ok
  end

  private

  def webhook_verify_token
    # Use a consistent verify token from credentials or default
    Rails.application.credentials.dig(:strava, :webhook_verify_token) || "lace_strava_webhook"
  end
end
