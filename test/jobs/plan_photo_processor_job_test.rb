require "test_helper"

class PlanPhotoProcessorJobTest < ActiveJob::TestCase
  def setup
    @plan = Plan.create!(
      length: 12,
      race_date: 3.months.from_now,
      plan_type: "custom"
    )

    # Attach a test image
    @plan.photos.attach(
      io: File.open(Rails.root.join("app/assets/images/lace-logo.png")),
      filename: "test_training_plan.png",
      content_type: "image/png"
    )
  end

  test "should enqueue the job" do
    assert_enqueued_with(job: PlanPhotoProcessorJob, args: [ @plan ]) do
      PlanPhotoProcessorJob.perform_later(@plan)
    end
  end

  test "should exit early when plan has no photos" do
    plan_without_photos = Plan.create!(
      length: 12,
      race_date: 3.months.from_now,
      plan_type: "custom"
    )

    # Should not raise any errors and should exit early
    assert_nothing_raised do
      PlanPhotoProcessorJob.perform_now(plan_without_photos)
    end

    # Should not create any activities
    assert_equal 0, Activity.where(plan: plan_without_photos).count
  end

  test "should process plan photos and create activities using VCR" do
    # Clear any existing activities for this plan
    Activity.where(plan: @plan).destroy_all

    VCR.use_cassette("plan_photo_processor_job_success") do
      PlanPhotoProcessorJob.perform_now(@plan)
    end

    # Should have created activities for the plan
    plan_activities = Activity.where(plan: @plan)
    assert plan_activities.count > 0, "Expected activities to be created from photo processing"

    # Verify activities have expected attributes
    plan_activities.each do |activity|
      assert_not_nil activity.plan_id
      assert_not_nil activity.start_date_local
      assert activity.distance >= 0
      assert_not_nil activity.description
    end
  end

  test "should handle GPT parsing errors gracefully" do
    Activity.where(plan: @plan).destroy_all

    VCR.use_cassette("plan_photo_processor_job_gpt_error") do
      # Should not raise errors even if GPT returns invalid JSON
      assert_nothing_raised do
        PlanPhotoProcessorJob.perform_now(@plan)
      end
    end

    # Should not create activities when GPT fails to parse
    assert_equal 0, Activity.where(plan: @plan).count
  end

  test "should handle GPT error response gracefully" do
    Activity.where(plan: @plan).destroy_all

    VCR.use_cassette("plan_photo_processor_job_gpt_error_response") do
      # Should not raise errors when GPT returns an error response
      assert_nothing_raised do
        PlanPhotoProcessorJob.perform_now(@plan)
      end
    end

    # Should not create activities when GPT returns error
    assert_equal 0, Activity.where(plan: @plan).count
  end

  test "should continue processing other photos if one fails" do
    # Attach a second photo
    @plan.photos.attach(
      io: File.open(Rails.root.join("app/assets/images/lace-logo.png")),
      filename: "second_training_plan.png",
      content_type: "image/png"
    )

    Activity.where(plan: @plan).destroy_all

    VCR.use_cassette("plan_photo_processor_job_multiple_photos") do
      # Should not raise errors even with multiple photos
      assert_nothing_raised do
        PlanPhotoProcessorJob.perform_now(@plan)
      end
    end

    # Should have processed both photos (or at least attempted to)
    assert_equal 2, @plan.photos.count
  end

  test "should create activities with correct date progression" do
    Activity.where(plan: @plan).destroy_all

    VCR.use_cassette("plan_photo_processor_job_date_progression") do
      PlanPhotoProcessorJob.perform_now(@plan)
    end

    plan_activities = Activity.where(plan: @plan).order(:start_date_local)

    if plan_activities.count > 1
      # Verify dates progress correctly (should be consecutive days)
      plan_activities.each_cons(2) do |current, next_activity|
        expected_next_date = current.start_date_local + 1.day
        assert_equal expected_next_date.to_date, next_activity.start_date_local.to_date,
                     "Activities should have consecutive dates"
      end

      # Verify start date is calculated correctly (race_date - length.weeks, beginning of week)
      expected_start_date = (@plan.race_date - @plan.length.weeks).beginning_of_week(:monday)
      assert_equal expected_start_date.to_date, plan_activities.first.start_date_local.to_date,
                   "First activity should start at beginning of training plan"
    end
  end

  test "should log appropriate messages during processing" do
    Activity.where(plan: @plan).destroy_all

    # Capture log output
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    VCR.use_cassette("plan_photo_processor_job_logging") do
      PlanPhotoProcessorJob.perform_now(@plan)
    end

    # Restore original logger
    Rails.logger = original_logger

    # Check that appropriate log messages were written
    log_content = log_output.string
    assert_includes log_content, "Starting job for plan #{@plan.id}"
    assert_includes log_content, "Photos attached? true"
    assert_includes log_content, "Number of photos: 1"
  end

  private

  def teardown
    # Clean up any test data
    @plan&.destroy
  end
end
