# Strava Webhook Integration - Architecture Refactor

## Overview

This document describes the refactored Strava webhook integration that separates raw Strava data tracking from planned workout management.

## Key Changes from Previous Implementation

### Problem with Original Approach
The original implementation created `Activity` records directly from webhook events. This was problematic because:
1. **Planned workouts and Strava activities mixed** - The `Activity` model is meant for workouts created from training plans
2. **No user review of matches** - Activities were auto-created without surfacing unmatched activities
3. **Lost context** - Raw Strava data wasn't preserved for reference
4. **Tight coupling** - Strava API logic was tightly coupled to activity creation

### New Approach
The refactored implementation introduces:
1. **`StravaActivity` model** - Stores raw Strava data from webhooks as a separate concern
2. **Matching algorithm** - Attempts to match Strava activities to user's planned workouts
3. **Job-based architecture** - All API interactions moved to background jobs
4. **User review flow** - Unmatched activities surface to users for manual linking

## Architecture

### Data Models

#### StravaActivity (NEW)
Stores raw data from Strava webhooks:
- `strava_id` - Unique identifier from Strava
- `strava_athlete_id` - Strava athlete/user ID
- `user_id` - Lace user who owns this activity
- `activity_type` - "Run", "Ride", etc.
- `distance` - In meters
- `start_date_local` - When activity occurred
- `webhook_payload` - Full raw JSON from Strava (for debugging/reference)
- `match_status` - "unmatched", "matched", or "linked"
- `activity_id` - FK to `Activity` if matched/linked to a planned workout

#### Activity (EXISTING - Unchanged)
Continues to represent planned workouts from training plans. Now can have an optional relationship to StravaActivity through the `activity_id` foreign key on StravaActivity.

### Job Architecture

```
webhook event from Strava
         ↓
ProcessStravaWebhookJob
  ├─ Creates/updates StravaActivity
  ├─ Queues FetchAndMatchStravaActivityJob on create/update
  └─ Queues DeleteStravaActivityJob on delete

FetchAndMatchStravaActivityJob
  ├─ Fetches full activity details from Strava API
  ├─ Stores in StravaActivity table (raw data)
  └─ Queues MatchStravaActivityJob

MatchStravaActivityJob
  ├─ Queries user's planned activities
  ├─ Calculates match scores (date, distance, type, description)
  ├─ Updates StravaActivity.match_status to "matched" or "unmatched"
  └─ Does NOT automatically link (user action required)

DeleteStravaActivityJob
  └─ Removes StravaActivity record
```

### API Calls

**RegisterStravaWebhookJob** and **DeleteStravaWebhookJob**:
- Moved Strava API calls from `StravaWebhookService` to jobs
- `StravaWebhookService` now just queues jobs (decorator pattern)

## Data Flow

### 1. Webhook Reception
```ruby
# POST /webhooks/strava
Webhooks::StravaController#event
  → ProcessStravaWebhookJob.perform_later(aspect_type, object_id, owner_id)
  → 200 OK to Strava immediately
```

### 2. Create/Update Activity
```ruby
ProcessStravaWebhookJob
  → FetchAndMatchStravaActivityJob.perform_later(user_id, strava_activity_id)

FetchAndMatchStravaActivityJob
  → Fetch from Strava API using user's access token
  → Create/update StravaActivity record with raw data
  → MatchStravaActivityJob.perform_later(strava_activity.id)

MatchStravaActivityJob
  → Query user's plans for matching workouts
  → Calculate match scores (60% threshold to mark as "matched")
  → Update StravaActivity.match_status
```

### 3. Delete Activity
```ruby
ProcessStravaWebhookJob
  → DeleteStravaActivityJob.perform_later(user_id, strava_activity_id)

DeleteStravaActivityJob
  → Find StravaActivity by user_id and strava_id
  → Destroy record
```

## Matching Algorithm

Located in `MatchStravaActivityJob#calculate_match_score`:

**Scoring Components** (must total ≥ 0.6 to match):
1. **Date Matching** (40% weight)
   - ±1 day tolerance
   - Score: 1.0 if same day, decreases with days difference

2. **Distance Matching** (35% weight)
   - ±10% tolerance (configurable)
   - Score: 1.0 if exact, decreases with variance

3. **Activity Type** (15% weight)
   - Must match (Run vs Run, Ride vs Ride, etc.)
   - Score: 1.0 if match, 0.0 if not

4. **Description Similarity** (10% weight)
   - Simple word overlap scoring
   - Useful for activities with specific notes

**Example Scoring**:
- Planned: 5km run on Jan 15 afternoon
- Strava: 5.1km run on Jan 15 morning
- Result: ~0.85 score → marked as "matched"

## API Changes

### Service Layer Simplified

**Before**: Service handled all API logic
```ruby
StravaWebhookService.create_subscription(user, callback_url)  # sync
```

**After**: Service queues jobs
```ruby
StravaWebhookService.create_subscription(user, callback_url)  # queues job
# Returns nil immediately
# Job executes async
```

### Benefits
- Non-blocking UI
- Retryable logic
- Better error handling
- Easier to test

## Migration Checklist

- [x] Create `StravaActivity` model
- [x] Create migration for `strava_activities` table
- [x] Refactor `ProcessStravaWebhookJob`
- [x] Create `FetchAndMatchStravaActivityJob`
- [x] Create `DeleteStravaActivityJob`
- [x] Create `MatchStravaActivityJob`
- [x] Create `RegisterStravaWebhookJob`
- [x] Create `DeleteStravaWebhookJob`
- [x] Update `StravaWebhookService` to queue jobs
- [x] Update tests
- [x] Add `StravaActivity` fixtures

## Next Steps (Future PRs)

1. **UI for Unmatched Activities** - Display StravaActivity records with match_status = "unmatched"
2. **Manual Linking** - Allow users to link unmatched StravaActivities to existing Activities
3. **Activity Dashboard** - Show synced activities with their match status
4. **Plan Creation Flow** - Add webhook toggle when users create plans
5. **Settings Page** - Manage webhook configuration per user

## Testing

### Test Coverage
- **ProcessStravaWebhookJob**: Tests job queuing for all event types
- **FetchAndMatchStravaActivityJob**: Tests API calls and StravaActivity creation
- **DeleteStravaActivityJob**: Tests deletion and edge cases
- **MatchStravaActivityJob**: Tests matching algorithm and scoring
- **RegisterStravaWebhookJob**: Tests webhook subscription registration
- **DeleteStravaWebhookJob**: Tests webhook subscription deletion
- **StravaWebhookService**: Tests job queueing and list/view operations

### VCR Cassettes
Tests use VCR to record and replay HTTP interactions for:
- Strava API calls (fetching activities)
- Strava webhook subscription management

### Fixtures
- `strava_activities.yml` - Test StravaActivity records
- `activities.yml` - Test planned Activity records (unchanged)
- `users.yml` - Test users (unchanged)

## Error Handling

All jobs implement graceful error handling:
- Missing users are logged but don't raise errors
- API failures are logged and re-raised for retry
- Duplicate StravaActivity records are found or created atomically
- Non-existent records on delete are logged as warnings

## Performance Considerations

### Database Indexes
- `strava_activities.user_id` - For user lookups
- `strava_activities.strava_id + user_id` - Unique constraint for quick lookups
- `strava_activities.user_id + match_status` - For finding unmatched activities

### Background Job Queue
- All jobs queue as `:default` (configurable in production)
- Consider separate queue for Strava API jobs if volume is high

### Strava API Rate Limits
- App-level rate limit: 600 requests per 15 minutes
- Per-athlete rate limit: 100 requests per 15 minutes
- Job errors should trigger exponential backoff via ActiveJob

## Configuration

### Environment Variables
```bash
STRAVA_WEBHOOK_VERIFY_TOKEN=your_token  # Optional, defaults to "lace_strava_webhook"
```

### Rails Credentials
```ruby
# rails credentials:edit
strava:
  client_id: YOUR_CLIENT_ID
  client_secret: YOUR_CLIENT_SECRET
  webhook_verify_token: YOUR_TOKEN  # Optional
```

## Deployment Notes

1. Run migrations before deploying job code
2. Jobs must be processable on both old and new code during rolling deployments
3. Monitor job failures during rollout
4. Consider gradual rollout with webhook registration opt-in

## Summary of Benefits

✅ **Separation of Concerns** - Raw Strava data separate from planned workouts
✅ **Non-Blocking** - All Strava API calls happen in background
✅ **User Agency** - Users review and approve matches before linking
✅ **Debuggable** - Raw webhook payload stored for troubleshooting
✅ **Scalable** - Job-based architecture allows rate limit handling
✅ **Testable** - Clear job responsibilities make testing easier
✅ **Maintainable** - Service layer simplified to job decorator pattern
