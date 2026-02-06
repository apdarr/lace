---
name: debugging
description: Use when debugging Rails issues - logs, console, breakpoints, SQL logging, N+1 queries, failing tests, stuck background jobs
---

# Debugging Rails Applications (Lace)

Lace is a Rails 8 application using SQLite, SolidQueue for background jobs, and the `debug` gem for breakpoint debugging.

## When to Use

- Rails application behaving unexpectedly
- Tests failing with unclear errors
- Performance issues or N+1 queries
- Production errors need investigation
- Background jobs failing or stuck

## Standards

- Always identify root cause, not just symptoms
- Add regression tests after fixing bugs
- Verify fix in both development and test environments
- Review logs for related issues
- Check performance impact of fixes
- Use `debug` gem (not byebug) for breakpoint debugging

---

## Log Investigation

### Development Logs

Tail the development log in real time:

```bash
tail -f log/development.log
```

### Filter by Severity

```bash
# Errors only
grep -i "error\|exception\|fatal" log/development.log

# Filter by request ID
grep "request_id_here" log/development.log
```

### Filter by Request or Controller

```bash
# Filter for a specific controller
grep "ActivitiesController" log/development.log

# Filter for slow requests
grep "Completed" log/development.log | grep -v "200 OK"
```

### Production Logs

```bash
tail -f log/production.log

# Recent errors in production
grep -i "error\|exception" log/production.log | tail -50
```

### Clear Logs

```bash
rails log:clear
```

---

## Rails Console

### Starting the Console

```bash
# Development
rails console

# Sandbox mode (rolls back all changes on exit)
rails console --sandbox

# Production (use with caution)
RAILS_ENV=production rails console
```

### Testing Models and Queries

```ruby
# Find records
User.first
Activity.where(user_id: 1).order(:start_date_local)

# Count and aggregate
Activity.count
Activity.group(:activity_type).count

# Check associations
user = User.find(1)
user.plans
user.activities
```

### Checking Validations

```ruby
record = Activity.new
record.valid?        # => false
record.errors        # => full error objects
record.errors.full_messages  # => ["Date can't be blank", ...]
```

### Inspecting Attributes

```ruby
record = Activity.first
record.attributes           # Hash of all attributes
record.changed?             # Has it been modified?
record.changes              # What changed?
record.persisted?           # Saved to database?
```

---

## Debugger (`debug` gem)

Rails 8 uses the `debug` gem (not byebug). Add breakpoints with `binding.break` or `debugger`.

### Adding Breakpoints

```ruby
def create
  @activity = Activity.new(activity_params)
  debugger  # execution pauses here
  # or: binding.break
  @activity.save
end
```

### Debugger Commands

| Command | Description |
|---|---|
| `next` (or `n`) | Execute next line (step over) |
| `step` (or `s`) | Step into method call |
| `continue` (or `c`) | Continue execution |
| `finish` | Run until current frame returns |
| `info` | Show local variables |
| `info locals` | Show all local variables |
| `info ivars` | Show instance variables |
| `p <expr>` | Evaluate and print expression |
| `pp <expr>` | Pretty-print expression |
| `where` (or `bt`) | Show backtrace |
| `up` | Move up one frame in the call stack |
| `down` | Move down one frame in the call stack |
| `break <file>:<line>` | Set a breakpoint at a specific location |
| `delete <id>` | Delete a breakpoint |
| `quit` | Exit the debugger |

### Conditional Breakpoints

```ruby
# Break only when a condition is met
debugger if @activity.distance.nil?
```

### Debugger in Tests

```ruby
test "should create activity" do
  debugger  # pause here during test execution
  post activities_url, params: { activity: { description: "Long Run" } }
  assert_response :redirect
end
```

---

## SQL Logging

### Enable Verbose SQL in Console

```ruby
# Show all SQL queries in the console
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Disable again
ActiveRecord::Base.logger = nil
```

### Inspect a Specific Query

```ruby
# See the SQL without executing
Activity.where(user_id: 1).to_sql
# => "SELECT \"activities\".* FROM \"activities\" WHERE \"activities\".\"user_id\" = 1"

# Explain the query plan (SQLite)
Activity.where(user_id: 1).explain
```

---

## Route Debugging

### List All Routes

```bash
rails routes
```

### Filter Routes

```bash
# Filter by controller
rails routes -c activities

# Filter by grep pattern
rails routes -g plan

# Filter by HTTP method
rails routes | grep "POST"
```

### Check a Specific Path

```ruby
# In the console
app.activities_path          # => "/activities"
app.activity_path(1)        # => "/activities/1"
```

---

## Database Status

### Migration Status

```bash
# Check which migrations have been run
rails db:migrate:status

# Current schema version
rails db:version
```

### Pending Migrations

```bash
# Run pending migrations
rails db:migrate

# Rollback the last migration
rails db:rollback

# Rollback multiple steps
rails db:rollback STEP=3
```

### SQLite-Specific

```bash
# Open the SQLite database directly
sqlite3 storage/development.sqlite3

# List tables
sqlite3 storage/development.sqlite3 ".tables"

# Show table schema
sqlite3 storage/development.sqlite3 ".schema activities"
```

---

## Rails Runner

### One-Liners

```bash
# Run a single expression
rails runner "puts User.count"

# Check a specific record
rails runner "pp Activity.find(1).attributes"

# Test an environment variable
rails runner "puts Rails.env"
```

### Scripts

```bash
# Run a script file
rails runner script/debug_check.rb
```

```ruby
# script/debug_check.rb
puts "Users: #{User.count}"
puts "Plans: #{Plan.count}"
puts "Activities: #{Activity.count}"
puts "Pending migrations: #{ActiveRecord::Migrator.new(:up, ActiveRecord::MigrationContext.new(Rails.root.join('db/migrate')).migrations).pending_migrations.count}"
```

---

## Test Debugging

### Verbose Test Output

```bash
# Run all tests with verbose output
rails test -v

# Run a single test file
rails test test/models/activity_test.rb -v

# Run a specific test by name
rails test test/models/activity_test.rb -n test_should_be_valid

# Run a specific test by line number
rails test test/models/activity_test.rb:10
```

### Reproduce Failures with Seed

```bash
# Run with a specific seed for reproducibility
rails test --seed 12345

# The seed is printed at the end of every test run
```

### Debugging Failing Tests

```ruby
# Add debugger to pause inside a test
test "activity should have a start_date_local" do
  activity = activities(:one)
  debugger
  assert activity.valid?
end
```

```bash
# Run tests with backtraces
rails test -b
```

---

## Common Issues

### N+1 Queries

**Detection:**

```ruby
# In the console, enable SQL logging and look for repeated queries
ActiveRecord::Base.logger = Logger.new(STDOUT)
user = User.find(1)
user.plans.each { |plan| plan.activities.count }
# Watch for repeated SELECT statements
```

```bash
# Search the logs for N+1 patterns
grep "SELECT" log/development.log | sort | uniq -c | sort -rn | head -20
```

**Solution:**

```ruby
# Use includes to eager-load associations
User.includes(plans: :activities).find(1)

# Use preload or eager_load when needed
Plan.preload(:activities).where(user_id: 1)
```

Consider adding the `bullet` gem to automatically detect N+1 queries in development.

### Missing Migrations

**Detection:**

```bash
rails db:migrate:status
# Look for "down" status on any migration
```

**Solution:**

```bash
rails db:migrate
```

If a migration is missing from the file system but recorded in the database:

```bash
# Check the schema_migrations table
rails runner "puts ActiveRecord::Base.connection.execute('SELECT * FROM schema_migrations').map { |r| r['version'] }"
```

### SolidQueue Job Debugging

**Check Pending Jobs:**

```ruby
# In the console
SolidQueue::Job.where(finished_at: nil).count
SolidQueue::Job.where(finished_at: nil).order(created_at: :desc).limit(10)
```

**Check Failed Jobs:**

```ruby
SolidQueue::FailedExecution.count
SolidQueue::FailedExecution.last
SolidQueue::FailedExecution.last&.error

# Inspect the error details
SolidQueue::FailedExecution.order(created_at: :desc).limit(5).each do |fe|
  puts "Job: #{fe.job.class_name} | Error: #{fe.error['message']}"
end
```

**Retry Failed Jobs:**

```ruby
# Retry a specific failed job
SolidQueue::FailedExecution.last.retry

# Retry all failed jobs
SolidQueue::FailedExecution.find_each(&:retry)
```

**Check Scheduled Jobs:**

```ruby
SolidQueue::ScheduledExecution.count
SolidQueue::ScheduledExecution.order(scheduled_at: :asc).limit(5)
```

**Clear Stuck Jobs:**

```ruby
# Find jobs that have been claimed but not finished
SolidQueue::ClaimedExecution.where("created_at < ?", 1.hour.ago)
```

---

## Verification Checklist

Before completing debugging work:

- ✅ Root cause identified (not just symptoms)
- ✅ Regression test added (prevents recurrence)
- ✅ Fix verified in development and test environments
- ✅ All tests passing
- ✅ Logs reviewed for related issues
- ✅ Performance impact verified (if applicable)

---

## Resources

- [Rails Debugging Guide](https://guides.rubyonrails.org/debugging_rails_applications.html)
- [`debug` gem documentation](https://github.com/ruby/debug)
- [SolidQueue README](https://github.com/rails/solid_queue)
- [SQLite documentation](https://www.sqlite.org/docs.html)
- [Active Record Query Interface](https://guides.rubyonrails.org/active_record_querying.html)
- [Rails Testing Guide](https://guides.rubyonrails.org/testing.html)
- [Bullet gem (N+1 detection)](https://github.com/flyerhzm/bullet)
