require "test_helper"

class PlanTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "enqueues SyncPlanToCalendarJob when calendar_sync_enabled is set to true" do
    plan = plans(:one)

    assert_enqueued_with(job: SyncPlanToCalendarJob, args: [plan.id]) do
      plan.update!(calendar_sync_enabled: true)
    end
  end

  test "enqueues RemovePlanCalendarEventsJob when calendar_sync_enabled is set to false" do
    plan = plans(:one)
    plan.update_columns(calendar_sync_enabled: true)

    assert_enqueued_with(job: RemovePlanCalendarEventsJob, args: [plan.id]) do
      plan.update!(calendar_sync_enabled: false)
    end
  end

  test "does not enqueue calendar jobs when calendar_sync_enabled is not changed" do
    plan = plans(:one)

    assert_no_enqueued_jobs(only: [SyncPlanToCalendarJob, RemovePlanCalendarEventsJob]) do
      plan.update!(length: 20)
    end
  end
end
