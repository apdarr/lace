require "test_helper"

class PlanPhotoProcessorJobTest < ActiveJob::TestCase
  def setup
    @plan = Plan.create!(
      length: 12,
      race_date: 3.months.from_now,
      plan_type: "custom"
    )

    # Use actual HEIC files from test/images directory
    file_path = Rails.root.join("test/images/IMG_5177.heic")
    @plan.photos.attach(
      io: File.open(file_path, "rb"),
      filename: "test_training_plan.heic",
      content_type: "image/heic"
    )

    # Ensure the attachment is saved and the blob is available
    @plan.save!
    @plan.reload
  end

  test "should enqueue the job" do
    # We only want to assert that the job is placed on the queue. The :test
    # adapter does NOT perform jobs automatically, so asserting performed
    # jobs here is incorrect (it would always be 0 unless we wrap in
    # perform_enqueued_jobs). This verifies serialization of the Plan arg.
    assert_enqueued_with(job: PlanPhotoProcessorJob, args: [ @plan ]) do
      PlanPhotoProcessorJob.perform_later(@plan)
    end
  end

  test "should perform the job when executed" do
    # We assert specifically that PlanPhotoProcessorJob is performed, ignoring other jobs (e.g., ActiveStorage::AnalyzeJob)
    perform_enqueued_jobs do
      PlanPhotoProcessorJob.perform_later(@plan)
    end
    assert_performed_with(job: PlanPhotoProcessorJob)
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

  # test "should handle GPT parsing errors gracefully" do
  #   Activity.where(plan: @plan).destroy_all

  #   VCR.use_cassette("plan_photo_processor_job_gpt_error") do
  #     # Should not raise errors even if GPT returns invalid JSON
  #     assert_nothing_raised do
  #       PlanPhotoProcessorJob.perform_now(@plan)
  #     end
  #   end

  #   # Should not create activities when GPT fails to parse
  #   assert_equal 0, Activity.where(plan: @plan).count
  # end

  test "should create activities with correct date progression" do
    Activity.where(plan: @plan).destroy_all

    VCR.use_cassette("plan_photo_processor_job_success") do
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

  test "should process multiple photos in a single combined request" do
    plan = Plan.create!(
      length: 4,
      race_date: 2.months.from_now,
      plan_type: "custom"
    )

    # Attach the real test images from test/images directory
    %w[IMG_5177.heic IMG_5178.heic].each do |filename|
      plan.photos.attach(
        io: File.open(Rails.root.join("test/images/#{filename}")),
        filename: filename,
        content_type: "image/heic"
      )
    end

    assert_equal 2, plan.photos.count

    Activity.where(plan: plan).destroy_all

    # Set initial status to queued (simulating the after_create callback)
    plan.update!(processing_status: "queued")

    VCR.use_cassette("plan_photo_processor_job_multi_photo") do
      PlanPhotoProcessorJob.perform_now(plan)
    end

    # Verify status was updated to completed
    plan.reload
    assert_equal "completed", plan.processing_status

    activities = Activity.where(plan: plan).order(:start_date_local)
    assert activities.count > 0, "Expected activities to be created from multi-photo processing"

    # Check date sequencing (should start at computed start date and be consecutive)
    expected_start_date = (plan.race_date - plan.length.weeks).beginning_of_week(:monday).to_date
    assert_equal expected_start_date, activities.first.start_date_local.to_date

    if activities.count > 1
      activities.each_cons(2) do |a, b|
        assert_equal a.start_date_local.to_date + 1, b.start_date_local.to_date, "Activities should have consecutive dates"
      end
    end

    # Verify activities have expected attributes
    activities.each do |activity|
      assert_not_nil activity.plan_id
      assert_not_nil activity.start_date_local
      assert activity.distance >= 0
      assert_not_nil activity.description
    end
  ensure
    plan&.destroy
  end

  private

  def teardown
    # Clean up any test data
    @plan&.destroy
  end
end
