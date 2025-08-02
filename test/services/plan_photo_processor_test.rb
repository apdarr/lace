require "test_helper"

class PlanPhotoProcessorTest < ActiveSupport::TestCase
  setup do
    @plan = Plan.create!(length: 12, race_date: "2025-06-01", plan_type: "custom")
  end

  test "can be instantiated with a plan" do
    processor = PlanPhotoProcessor.new(@plan)
    assert_not_nil processor
  end

  test "skips processing when no photos attached" do
    processor = PlanPhotoProcessor.new(@plan)
    
    # Should handle gracefully when no photos are attached
    processor.process_photos
    assert true # No error should occur
  end
end