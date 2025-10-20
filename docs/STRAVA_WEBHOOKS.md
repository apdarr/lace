# Strava Webhook Integration

This document describes how to set up and use the Strava webhook integration for automatic activity syncing.

## Overview

The Strava webhook integration allows Lace to automatically receive and process new activities as they are created, updated, or deleted in Strava. This replaces the need for manual bulk imports and keeps your activity data synchronized in real-time.

## Architecture

The webhook system consists of the following components:

1. **Webhook Controller** (`app/controllers/webhooks/strava_controller.rb`):
   - Handles webhook verification (GET request from Strava)
   - Receives webhook events (POST request from Strava)
   - Queues background jobs to process events

2. **Webhook Service** (`app/services/strava_webhook_service.rb`):
   - Manages webhook subscription lifecycle (create, delete, list, view)
   - Communicates with Strava Push Subscriptions API
   - Stores subscription ID and verify token on user model

3. **Background Job** (`app/jobs/process_strava_webhook_job.rb`):
   - Fetches activity details from Strava API
   - Creates, updates, or deletes activities in the database
   - Handles errors gracefully

## Setup

### 1. Environment Configuration

Add the following environment variables or Rails credentials:

```ruby
# config/credentials.yml.enc (edit with: rails credentials:edit)
strava:
  client_id: YOUR_STRAVA_CLIENT_ID
  client_secret: YOUR_STRAVA_CLIENT_SECRET
  webhook_verify_token: YOUR_VERIFY_TOKEN  # optional, defaults to "lace_strava_webhook"
```

Or use environment variables:
```bash
export STRAVA_CLIENT_ID=your_client_id
export STRAVA_CLIENT_SECRET=your_client_secret
export STRAVA_WEBHOOK_VERIFY_TOKEN=your_verify_token  # optional
```

### 2. Database Migrations

Run the migrations to add webhook tracking fields:

```bash
rails db:migrate
```

This adds:
- `strava_webhook_subscription_id` to users table
- `webhook_verify_token` to users table
- `webhook_enabled` to plans table

### 3. Create Webhook Subscription

To register a webhook subscription for a user:

```ruby
# In a Rails console or rake task
user = User.find_by(email_address: "user@example.com")
callback_url = "https://yourdomain.com/webhooks/strava"

StravaWebhookService.create_subscription(user, callback_url)
```

**Important Notes:**
- The callback URL must be publicly accessible via HTTPS
- Strava will send a verification request to the callback URL during subscription creation
- **Strava API Limitation**: Each Strava application can only have ONE active webhook subscription at a time, shared across all users. This is a Strava API constraint, not an application design choice.
- For multi-user applications, this means you should create one application-wide subscription that handles events for all users
- The webhook endpoint identifies which user the event belongs to using the `owner_id` field (Strava athlete ID) in the webhook payload
- You'll need to use ngrok or similar for local development testing

### 4. Webhook Endpoints

The webhook integration exposes two endpoints:

#### Verification Endpoint (GET)
```
GET /webhooks/strava?hub.mode=subscribe&hub.verify_token=TOKEN&hub.challenge=CHALLENGE
```

This endpoint is called by Strava to verify your webhook endpoint. It responds with the challenge token if the verify token matches.

#### Event Endpoint (POST)
```
POST /webhooks/strava
```

This endpoint receives webhook events from Strava. Event payload example:

```json
{
  "aspect_type": "create",
  "object_type": "activity",
  "object_id": 123456789,
  "owner_id": 987654321,
  "subscription_id": 12345,
  "event_time": 1516126040
}
```

## Usage

### Registering a Subscription

```ruby
# Find a user to associate the subscription with
# In a multi-user app, you can use any user or a dedicated system user
user = User.find(1)  # Or User.find_by(strava_id: your_strava_id)

callback_url = Rails.application.routes.url_helpers.webhooks_strava_url(
  host: "yourdomain.com",
  protocol: "https"
)

subscription_id = StravaWebhookService.create_subscription(user, callback_url)
# => "12345"
```

**Note**: Although the subscription is associated with a user for token storage, it handles events for all users in your application. The `owner_id` in webhook events identifies which user the activity belongs to.

### Viewing Subscriptions

```ruby
# List all subscriptions for your app
subscriptions = StravaWebhookService.list_subscriptions
# => [{"id"=>12345, "application_id"=>67890, "callback_url"=>"https://...", ...}]

# View specific subscription
subscription = StravaWebhookService.view_subscription("12345")
# => {"id"=>12345, "application_id"=>67890, ...}
```

### Deleting a Subscription

```ruby
# Find the user who owns the subscription (has the subscription_id stored)
user = User.find_by.not(strava_webhook_subscription_id: nil).first
# Or if you know the user ID: User.find(1)

StravaWebhookService.delete_subscription(user)
```

**Note**: Because Strava only allows one subscription per application, deleting it will stop webhook events for all users. Make sure you intend to disable webhooks entirely before deleting.

## Event Processing

When a webhook event is received:

1. The webhook controller validates the event
2. If the event is for an activity, it queues a `ProcessStravaWebhookJob`
3. The job:
   - Finds the user by their Strava ID
   - Fetches the activity details from Strava API using the user's access token
   - Creates, updates, or deletes the activity in the database

### Event Types

- **create**: A new activity was created on Strava
- **update**: An existing activity was updated on Strava
- **delete**: An activity was deleted on Strava

## Testing

### Running Tests

```bash
# Run all webhook tests
bundle exec rails test test/controllers/webhooks/
bundle exec rails test test/jobs/process_strava_webhook_job_test.rb
bundle exec rails test test/services/strava_webhook_service_test.rb
```

### VCR Cassettes

The tests use VCR to record and replay HTTP interactions. Cassettes are stored in `test/vcr_cassettes/`.

## Troubleshooting

### Webhook Not Receiving Events

1. Verify the callback URL is publicly accessible via HTTPS
2. Check that the subscription is active: `StravaWebhookService.list_subscriptions`
3. Review Rails logs for incoming requests to `/webhooks/strava`

### Subscription Creation Fails

1. Verify Strava credentials are correct
2. Ensure only one subscription exists (delete old ones if needed)
3. Check that the callback URL passes Strava's verification

### Activities Not Syncing

1. Check background job logs for errors
2. Verify user's access token is valid and not expired
3. Ensure the user exists in the database with the correct `strava_id`

## Security

- Webhook endpoints skip CSRF protection (required for Strava POST requests)
- Webhook endpoints skip authentication (required for Strava GET verification)
- Verify tokens should be kept secret and rotated periodically
- Consider implementing IP allowlisting for webhook endpoints

## References

- [Strava Webhook Events API Documentation](https://developers.strava.com/docs/webhooks/)
- [Strava Push Subscriptions API](https://developers.strava.com/docs/webhookexample/)
