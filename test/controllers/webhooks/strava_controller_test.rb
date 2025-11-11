require "test_helper"

class Webhooks::StravaControllerTest < ActionDispatch::IntegrationTest
  setup do
    @verify_token = ENV["STRAVA_WEBHOOK_VERIFY_TOKEN"].presence || "lace_strava_webhook"
    @valid_challenge = "test_challenge_token"
  end

  test "verify endpoint returns challenge with valid token" do
    get webhooks_strava_url, params: {
      "hub.mode": "subscribe",
      "hub.verify_token": @verify_token,
      "hub.challenge": @valid_challenge
    }

    assert_response :success
    response_json = JSON.parse(response.body)
    assert_equal @valid_challenge, response_json["hub.challenge"]
  end

  test "verify endpoint returns forbidden with invalid token" do
    get webhooks_strava_url, params: {
      "hub.mode": "subscribe",
      "hub.verify_token": "invalid_token",
      "hub.challenge": @valid_challenge
    }

    assert_response :forbidden
  end

  test "verify endpoint returns forbidden with invalid mode" do
    get webhooks_strava_url, params: {
      "hub.mode": "invalid",
      "hub.verify_token": @verify_token,
      "hub.challenge": @valid_challenge
    }

    assert_response :forbidden
  end

  test "event endpoint accepts activity create events" do
    user = users(:one)

    assert_enqueued_with(job: ProcessStravaWebhookJob) do
      post webhooks_strava_url, params: {
        aspect_type: "create",
        object_type: "activity",
        object_id: 123456,
        owner_id: user.strava_id
      }
    end

    assert_response :ok
  end

  test "event endpoint accepts activity update events" do
    user = users(:one)

    assert_enqueued_with(job: ProcessStravaWebhookJob) do
      post webhooks_strava_url, params: {
        aspect_type: "update",
        object_type: "activity",
        object_id: 123456,
        owner_id: user.strava_id
      }
    end

    assert_response :ok
  end

  test "event endpoint accepts activity delete events" do
    user = users(:one)

    assert_enqueued_with(job: ProcessStravaWebhookJob) do
      post webhooks_strava_url, params: {
        aspect_type: "delete",
        object_type: "activity",
        object_id: 123456,
        owner_id: user.strava_id
      }
    end

    assert_response :ok
  end

  test "event endpoint ignores non-activity events" do
    assert_no_enqueued_jobs do
      post webhooks_strava_url, params: {
        aspect_type: "update",
        object_type: "athlete",
        object_id: 123456,
        owner_id: 789
      }
    end

    assert_response :ok
  end
end
