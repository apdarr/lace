---
name: testing
description: Use when testing Rails applications - TDD, Minitest, fixtures, VCR, system tests with Capybara, model and controller testing
---

# Testing Skill — Lace (Rails 8 / Minitest)

> Lace uses **Minitest**, **fixtures**, **VCR + WebMock**, **Capybara + Selenium**, and **SimpleCov**.
> Run tests with `rails test`. Run system tests with `rails test:system`.

---

## TDD: Red-Green-Refactor

<tdd-cycle>

Always follow the **Red → Green → Refactor** cycle:

1. **Red** — Write a failing test that describes the desired behavior.
2. **Green** — Write the minimum production code to make the test pass.
3. **Refactor** — Clean up both test and production code while keeping tests green.

```ruby
# 1. RED — write the test first
test "activity displays formatted distance" do
  activity = activities(:morning_run)
  assert_equal "5.00 mi", activity.formatted_distance
end

# 2. GREEN — implement the method
class Activity < ApplicationRecord
  def formatted_distance
    "#{format('%.2f', distance)} mi"
  end
end

# 3. REFACTOR — extract constant, improve naming, etc.
```

Commit rhythm: **test → implementation → refactor → commit**.

</tdd-cycle>

---

## Test Structure

<basic-test-structure>

```ruby
require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  test "the truth" do
    assert true
  end
end
```

Key conventions:
- Require `"test_helper"` (model/job/controller tests) or `"application_system_test_case"` (system tests).
- Test classes inherit from `ActiveSupport::TestCase` (models), `ActionDispatch::IntegrationTest` (controllers), `ActiveJob::TestCase` (jobs), or `ApplicationSystemTestCase` (system tests).
- Use the `test "description" do … end` macro — never `def test_something`.
- One assertion **concept** per test method.

</basic-test-structure>

<setup-and-teardown>

```ruby
class PlanTest < ActiveSupport::TestCase
  setup do
    @plan = plans(:one)
    @user = users(:one)
  end

  teardown do
    # Clean up external state if necessary
  end

  test "plan belongs to a user" do
    assert_equal @user, @plan.user
  end
end
```

- Use `setup` for common test data preparation — load fixtures, set defaults.
- Use `teardown` sparingly — only when external state must be cleaned up (e.g., OmniAuth mocks).
- Fixtures are loaded automatically via `fixtures :all` in `test_helper.rb`.

</setup-and-teardown>

---

## Minitest Assertions

<common-assertions>

```ruby
# Truthiness
assert value                          # truthy
refute value                          # falsy
assert_not value                      # Rails alias for refute

# Equality & identity
assert_equal expected, actual
assert_not_equal unexpected, actual
assert_same expected, actual          # object identity (equal?)

# Nil checks
assert_nil value
assert_not_nil value

# Type / inclusion
assert_instance_of User, @user
assert_kind_of ApplicationRecord, @user
assert_includes collection, item
assert_not_includes collection, item

# Numeric / comparison
assert_in_delta 3.14, calculated, 0.01
assert_operator value, :>, 0

# Strings / patterns
assert_match /running/i, activity.description
assert_empty collection

# Exceptions
assert_raises(ActiveRecord::RecordInvalid) { user.save! }

# Database count changes
assert_difference("Plan.count") { post plans_url, params: valid_params }
assert_difference("Plan.count", -1) { delete plan_url(@plan) }
assert_no_difference("Plan.count") { post plans_url, params: invalid_params }

# Response assertions (controller / integration tests)
assert_response :success          # 200
assert_response :redirect         # 3xx
assert_response :not_found        # 404
assert_response :forbidden        # 403
assert_redirected_to plans_url

# HTML assertions (controller / integration tests)
assert_select "h1", text: "Training Plan"
assert_select "form[action='#{profile_path}'][method='post']"
assert_select "#notice", text: /enabled/i

# Job assertions
assert_enqueued_with(job: ProcessStravaWebhookJob) { post webhooks_strava_url, params: event_params }
assert_no_enqueued_jobs { perform_action }
```

</common-assertions>

---

## Model Testing

<model-validations>

### Validations

```ruby
class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  # Presence
  test "requires strava_id" do
    @user.strava_id = nil
    assert_not @user.valid?
    assert_includes @user.errors[:strava_id], "can't be blank"
  end

  # Format
  test "email must be valid format" do
    @user.email = "invalid"
    assert_not @user.valid?
    assert_includes @user.errors[:email], "is invalid"
  end

  # Length
  test "first_name must not exceed 100 characters" do
    @user.first_name = "a" * 101
    assert_not @user.valid?
  end

  # Uniqueness
  test "strava_id must be unique" do
    duplicate = @user.dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:strava_id], "has already been taken"
  end

  # Custom validation
  test "race_date must be in the future" do
    plan = plans(:one)
    plan.race_date = Date.yesterday
    assert_not plan.valid?
    assert_includes plan.errors[:race_date], "must be in the future"
  end
end
```

</model-validations>

<model-associations>

### Associations

```ruby
class PlanTest < ActiveSupport::TestCase
  setup do
    @plan = plans(:one)
    @user = users(:one)
  end

  # belongs_to
  test "belongs to a user" do
    assert_equal @user, @plan.user
    assert_instance_of User, @plan.user
  end

  # has_many
  test "has many activities" do
    assert_respond_to @plan, :activities
    assert_kind_of ActiveRecord::Associations::CollectionProxy, @plan.activities
  end

  # dependent: :destroy
  test "destroying plan destroys associated activities" do
    activity = Activity.create!(plan: @plan, user: @user, distance: 5.0, description: "Test", start_date_local: Time.current)
    assert_difference("Activity.count", -1) do
      @plan.destroy
    end
  end
end
```

</model-associations>

<model-scopes>

### Scopes

```ruby
class ActivityTest < ActiveSupport::TestCase
  # Time-based scope
  test ".upcoming returns activities with future dates" do
    upcoming = Activity.upcoming
    upcoming.each do |activity|
      assert activity.start_date_local >= Time.current
    end
  end

  # Status-based scope
  test ".completed returns only completed activities" do
    completed = Activity.completed
    completed.each do |activity|
      assert activity.completed?
    end
  end

  # Scope chaining
  test ".recent returns activities ordered by date descending" do
    activities = Activity.recent
    activities.each_cons(2) do |a, b|
      assert_operator a.start_date_local, :>=, b.start_date_local
    end
  end
end
```

</model-scopes>

<model-callbacks>

### Callbacks

```ruby
class PlanTest < ActiveSupport::TestCase
  # after_create
  test "generates weekly structure after creation" do
    plan = Plan.create!(
      user: users(:one),
      race_date: Date.current + 3.months,
      length: 12,
      plan_type: "template"
    )
    assert_not_empty plan.weeks
  end

  # before_save
  test "normalizes description before saving" do
    activity = activities(:morning_run)
    activity.description = "  extra   spaces  "
    activity.save!
    assert_equal "extra spaces", activity.description
  end
end
```

</model-callbacks>

<model-instance-methods>

### Instance Methods & State Transitions

```ruby
class PlanTest < ActiveSupport::TestCase
  test "#custom? returns true for custom plans" do
    plan = Plan.new(plan_type: "custom")
    assert plan.custom?
  end

  test "#template? returns true for template plans" do
    plan = Plan.new(plan_type: "template")
    assert plan.template?
  end

  test "#days_until_race calculates correctly" do
    plan = plans(:one)
    plan.race_date = Date.current + 30.days
    assert_equal 30, plan.days_until_race
  end
end
```

</model-instance-methods>

<model-enums>

### Enums

```ruby
class PlanTest < ActiveSupport::TestCase
  test "plan_type enum values" do
    assert Plan.plan_types.key?("template")
    assert Plan.plan_types.key?("custom")
  end

  test "predicate methods work for enum" do
    plan = Plan.new(plan_type: :custom)
    assert plan.custom?
    assert_not plan.template?
  end

  test "enum scope filters correctly" do
    custom_plans = Plan.custom
    custom_plans.each { |p| assert p.custom? }
  end
end
```

</model-enums>

<model-class-methods>

### Class Methods

```ruby
class ActivityTest < ActiveSupport::TestCase
  test ".for_user returns activities belonging to user" do
    user = users(:one)
    activities = Activity.for_user(user)
    activities.each do |activity|
      assert_equal user.id, activity.user_id
    end
  end

  test ".total_distance sums distances" do
    user = users(:one)
    expected = user.activities.sum(:distance)
    assert_equal expected, Activity.total_distance(user)
  end
end
```

</model-class-methods>

<model-edge-cases>

### Edge Cases

```ruby
class PlanTest < ActiveSupport::TestCase
  # Boundary conditions
  test "length cannot be zero" do
    plan = Plan.new(length: 0, user: users(:one), race_date: 1.month.from_now)
    assert_not plan.valid?
  end

  test "length cannot be negative" do
    plan = Plan.new(length: -1, user: users(:one), race_date: 1.month.from_now)
    assert_not plan.valid?
  end

  # Nil safety
  test "handles nil distance gracefully" do
    activity = Activity.new(distance: nil)
    assert_nil activity.formatted_distance
  end

  # Error handling
  test "raises on invalid plan type" do
    assert_raises(ArgumentError) do
      Plan.new(plan_type: "invalid")
    end
  end
end
```

</model-edge-cases>

---

## Controller / Integration Testing

<controller-action-tests>

Controller tests in Lace are integration tests inheriting from `ActionDispatch::IntegrationTest`.
Use `sign_in_as(@user)` from `AuthenticationHelpers` for authenticated routes.

```ruby
require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @plan = plans(:one)
    @plan.update!(race_date: Date.current + 30.days)
    sign_in_as(@user)
  end

  # INDEX
  test "should get index" do
    get plans_url
    assert_response :success
  end

  # SHOW
  test "should show plan" do
    get plan_url(@plan)
    assert_response :success
  end

  # NEW
  test "should get new" do
    get new_plan_url
    assert_response :success
  end

  # CREATE
  test "should create plan" do
    assert_difference("Plan.count") do
      post plans_url, params: {
        plan: { length: 12, race_date: @plan.race_date, plan_type: "template" }
      }
    end
    assert_redirected_to plan_url(Plan.last)
  end

  # UPDATE
  test "should update plan" do
    patch plan_url(@plan), params: {
      plan: { length: @plan.length, race_date: @plan.race_date }
    }
    assert_redirected_to plan_url(@plan)
  end

  # DESTROY
  test "should destroy plan" do
    assert_difference("Plan.count", -1) do
      delete plan_url(@plan)
    end
    assert_redirected_to plans_url
  end

  # Authentication required
  test "redirects unauthenticated user" do
    reset!  # clear session
    get plans_url
    assert_response :redirect
  end

  # JSON response
  test "returns JSON for webhook verification" do
    get webhooks_strava_url, params: {
      "hub.mode": "subscribe",
      "hub.verify_token": "valid_token",
      "hub.challenge": "challenge_token"
    }
    response_json = JSON.parse(response.body)
    assert_equal "challenge_token", response_json["hub.challenge"]
  end

  # Enqueuing jobs from controller actions
  test "webhook enqueues processing job" do
    assert_enqueued_with(job: ProcessStravaWebhookJob) do
      post webhooks_strava_url, params: {
        aspect_type: "create",
        object_type: "activity",
        object_id: 123456,
        owner_id: @user.strava_id
      }
    end
    assert_response :ok
  end
end
```

### Testing with VCR in Controllers

```ruby
test "enabling webhooks creates subscription" do
  VCR.use_cassette("strava_webhook_register") do
    patch profile_path, params: {
      profile_settings: { enable_strava_webhooks: "1" }
    }

    assert_redirected_to profile_path
    follow_redirect!
    assert_select "#notice", text: /enabled/i

    @user.reload
    assert_not_nil @user.strava_webhook_subscription_id
  end
end
```

</controller-action-tests>

---

## Job Testing

<job-tests>

Job tests inherit from `ActiveJob::TestCase` and use `perform_now` for synchronous execution or `assert_enqueued_with` to verify enqueueing.

```ruby
require "test_helper"

class ProcessStravaWebhookJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
  end

  # Test that a job enqueues another job
  test "create event enqueues fetch job" do
    assert_enqueued_with(job: FetchAndMatchStravaActivityJob) do
      ProcessStravaWebhookJob.perform_now(
        aspect_type: "create",
        object_id: 12345678901,
        owner_id: @user.strava_id
      )
    end
  end

  # Test that no jobs are enqueued
  test "unknown user enqueues nothing" do
    assert_no_enqueued_jobs do
      ProcessStravaWebhookJob.perform_now(
        aspect_type: "create",
        object_id: 123456789,
        owner_id: 999999999
      )
    end
  end

  # Perform job with VCR cassette (for jobs that make HTTP calls)
  test "creates embeddings for all activities" do
    VCR.use_cassette("embeddings_job") do
      CreateEmbeddingsJob.perform_now
      Activity.all.each do |activity|
        assert_not_nil activity.embedding
      end
    end
  end

  # Test job performs inline (useful for integration-style job tests)
  test "processes webhook end-to-end" do
    perform_enqueued_jobs do
      VCR.use_cassette("strava_activity_fetch") do
        ProcessStravaWebhookJob.perform_now(
          aspect_type: "create",
          object_id: 12345,
          owner_id: @user.strava_id
        )
      end
    end
  end
end
```

</job-tests>

---

## System Testing with Capybara

<system-tests>

System tests use Capybara with headless Chrome via Selenium. They inherit from `ApplicationSystemTestCase` and test full user flows in a real browser.

### Base Class

```ruby
# test/application_system_test_case.rb
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  OmniAuth.config.test_mode = true
  OmniAuth.config.path_prefix = "/auth"
end
```

### Authentication in System Tests

System tests cannot use `sign_in_as` (cookie-based). Instead, mock OmniAuth and visit the callback URL directly:

```ruby
class PlansTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)

    OmniAuth.config.mock_auth[:strava] = OmniAuth::AuthHash.new({
      provider: "strava",
      uid: "123456",
      info: {
        first_name: "Test",
        last_name: "User",
        email: "test@example.com",
        profile: "http://example.com/test_user.jpg"
      },
      credentials: {
        token: "mock_token",
        refresh_token: "mock_refresh_token",
        expires_at: 1.week.from_now.to_i
      }
    })
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:strava]

    login!
  end

  teardown do
    OmniAuth.config.mock_auth[:strava] = nil
  end

  private

  def login!
    visit "/auth/strava/callback"
  end
end
```

### Capybara Actions & Assertions

```ruby
# Navigation
visit plans_path
visit new_plan_path

# Clicking
click_on "New Plan"
click_button "Create Plan"
click_link "Edit"

# Forms
fill_in "plan[length]", with: 12
fill_in "plan[race_date]", with: (Date.current + 3.months).strftime("%Y-%m-%d")
select "Create Custom Plan (Advanced)", from: "plan[plan_type]"
check "Enable notifications"
uncheck "Enable notifications"
choose "Weekly"
attach_file "plan[photos][]", Rails.root.join("test/images/sample_plan.jpg")

# Text assertions
assert_text "Plan was successfully created"
assert_no_text "Error"

# Selector assertions
assert_selector "h1", text: "Training Plan"
assert_selector "form"
assert_selector "input[type='file'][name='plan[photos][]']"
assert_no_selector ".error-message"

# Button / link assertions
assert_button "Create Plan"
assert_link "Edit"

# Path assertions
assert_current_path plan_path(Plan.last)
assert_current_path plans_path

# Finding elements
week_selector = find("select[name='week']")
assert_operator week_selector.all("option").length, :>, 1

# Visibility
assert_selector "[data-plan-form-target='photosSection']", visible: true

# Confirmations (browser dialogs)
accept_confirm { click_on "Delete plan" }

# Conditional interactions
if has_link?("New Plan")
  click_on "New Plan"
else
  visit new_plan_path
end

# Waiting (Capybara auto-waits, but you can be explicit)
assert_selector "h1", text: "Training Plan", wait: 5
```

### Full System Test Example

```ruby
require "application_system_test_case"

class SessionsTest < ApplicationSystemTestCase
  setup do
    OmniAuth.config.mock_auth[:strava] = OmniAuth::AuthHash.new({
      provider: "strava",
      uid: "123456",
      info: { first_name: "Test", last_name: "User" },
      credentials: {
        token: "mock_token",
        refresh_token: "mock_refresh_token",
        expires_at: 1.week.from_now.to_i
      }
    })
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:strava]
  end

  teardown do
    OmniAuth.config.mock_auth[:strava] = nil
  end

  test "visit the login page" do
    visit new_session_path
    assert_selector "h1", text: "Welcome to Lace"
    assert_button "Continue with Strava"
  end

  test "should sign in and sign out with Strava" do
    visit new_session_path
    click_button "Continue with Strava"

    assert_current_path root_path
    assert_text "Successfully signed in with Strava!"

    click_button "Sign out"
    assert_current_path root_path
    assert_text "Successfully signed out!"
  end
end
```

</system-tests>

---

## VCR Usage

<vcr-usage>

Lace uses **VCR** with **WebMock** to record and replay HTTP interactions (Strava API, OpenAI, etc.). This prevents live API calls in tests and ensures deterministic results.

### Configuration (test_helper.rb)

```ruby
VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock

  # Allow localhost requests (Capybara, Selenium)
  config.ignore_request do |request|
    uri = request.uri.to_s
    uri.include?("127.0.0.1") || uri.include?("localhost")
  end

  # Filter sensitive data from recorded cassettes
  config.filter_sensitive_data("<BEARER_TOKEN>") do |interaction|
    auth_header = interaction.request.headers["Authorization"]&.first
    auth_header&.match(/Bearer (.+)/)&.[](1)
  end

  config.filter_sensitive_data("<STRAVA_CLIENT_ID>") do |interaction|
    Rails.application.credentials.dig(:strava, :client_id)&.to_s
  end

  config.filter_sensitive_data("<STRAVA_CLIENT_SECRET>") do |interaction|
    Rails.application.credentials.dig(:strava, :client_secret)&.to_s
  end
end
```

### Recording Cassettes

```ruby
# Wrap any code that makes HTTP requests in VCR.use_cassette
test "fetches Strava activities" do
  VCR.use_cassette("strava/activities") do
    activities = StravaClient.new(@user).fetch_activities
    assert_not_empty activities
  end
end

# Cassette is saved to test/vcr_cassettes/strava/activities.yml
# Subsequent runs replay the recorded response
```

### Cassette Recording Modes

```ruby
# Default: :none — only replay, error if no cassette exists
VCR.use_cassette("strava/activities") do
  # uses existing cassette or raises error
end

# :new_episodes — record new requests, replay existing ones
VCR.use_cassette("strava/activities", record: :new_episodes) do
  # adds new interactions to existing cassette
end

# :all — always re-record (useful for refreshing stale cassettes)
VCR.use_cassette("strava/activities", record: :all) do
  # re-records everything
end

# :once — record once, then always replay
VCR.use_cassette("strava/activities", record: :once) do
  # records on first run, replays after
end
```

### Re-recording Cassettes

When an API changes or cassettes become stale:

```bash
# Delete the cassette file and re-run the test
rm test/vcr_cassettes/strava/activities.yml
rails test test/controllers/activities_controller_test.rb

# Or use record: :all temporarily
```

```ruby
# Temporarily force re-record in the test
VCR.use_cassette("strava/activities", record: :all) do
  # This will make a real HTTP request and save the new response
end
# Remember to remove `record: :all` after re-recording!
```

### Filtering Sensitive Data

Always filter credentials and tokens so they are not committed to version control:

```ruby
VCR.configure do |config|
  # Filter by inspecting request/response
  config.filter_sensitive_data("<BEARER_TOKEN>") do |interaction|
    auth_header = interaction.request.headers["Authorization"]&.first
    auth_header&.match(/Bearer (.+)/)&.[](1)
  end

  # Filter by credential value
  config.filter_sensitive_data("<API_KEY>") do
    Rails.application.credentials.dig(:openai, :api_key)
  end

  # Filter request body content
  config.filter_sensitive_data("<OPENAI_REQUEST_BODY>") do |interaction|
    if interaction.request.uri.include?("openai")
      body = interaction.request.body
      body if body.match?(/\{"model":"text-embedding.*"input":".*"\}/)
    end
  end
end
```

### VCR with Jobs

```ruby
test "creates embeddings for all activities" do
  VCR.use_cassette("embeddings_job") do
    CreateEmbeddingsJob.perform_now
    Activity.all.each do |activity|
      assert_not_nil activity.embedding
    end
  end
end
```

### VCR with Controller Tests

```ruby
test "enabling webhooks creates subscription" do
  VCR.use_cassette("strava_webhook_register") do
    patch profile_path, params: {
      profile_settings: { enable_strava_webhooks: "1" }
    }
    assert_redirected_to profile_path
    @user.reload
    assert_not_nil @user.strava_webhook_subscription_id
  end
end
```

</vcr-usage>

---

## Standards

<standards>

- Write tests **FIRST** when possible (Red-Green-Refactor cycle).
- Use **Minitest**, never RSpec.
- Test classes inherit from `ActiveSupport::TestCase` (models), `ActionDispatch::IntegrationTest` (controllers), `ActiveJob::TestCase` (jobs), or `ApplicationSystemTestCase` (system tests).
- Use `test "description" do` macro for readable test names.
- Use **fixtures** for test data (in `test/fixtures/`).
- Use `assert` and `refute` for assertions.
- One assertion **concept** per test method.
- Use `setup` for common test preparation.
- Use `sign_in_as(@user)` for authentication in controller/integration tests.
- Mock OmniAuth and visit `/auth/strava/callback` for authentication in system tests.
- Use **VCR** to record and replay HTTP interactions — never make live API calls in tests.
- Use **WebMock** to prevent accidental live HTTP requests.
- Filter sensitive data (tokens, API keys, credentials) in VCR cassettes.
- Use system tests with **Capybara + headless Chrome** for full-stack user flows.
- Run tests with `rails test` and system tests with `rails test:system`.
- Fixtures are auto-loaded via `fixtures :all` in `test_helper.rb`.
- Use `perform_enqueued_jobs` for integration-style job tests.
- Use `assert_enqueued_with` and `assert_no_enqueued_jobs` for unit-style job tests.
- Use `assert_difference` and `assert_no_difference` for database state changes.

</standards>

---

## Resources

- [Minitest Documentation](https://docs.seattlerb.org/minitest/)
- [Rails Testing Guide](https://guides.rubyonrails.org/testing.html)
- [Rails System Testing](https://guides.rubyonrails.org/testing.html#system-testing)
- [Capybara README](https://github.com/teamcapybara/capybara)
- [VCR Documentation](https://github.com/vcr/vcr)
- [WebMock Documentation](https://github.com/bblimke/webmock)
- [Rails Fixtures Guide](https://guides.rubyonrails.org/testing.html#the-low-down-on-fixtures)
- [ActiveJob Testing](https://guides.rubyonrails.org/testing.html#testing-jobs)
