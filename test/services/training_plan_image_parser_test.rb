require "test_helper"

class TrainingPlanImageParserTest < ActiveSupport::TestCase
  test "parser should return mock workout data" do
    # Create a temporary file to simulate an image
    temp_file = Tempfile.new(['test_image', '.jpg'])
    temp_file.write("mock image data")
    temp_file.close

    parser = TrainingPlanImageParser.new(temp_file.path)
    result = parser.parse_workouts

    assert_not_nil result["weeks"]
    assert_equal 1, result["weeks"].length
    
    week = result["weeks"].first
    assert_equal 1, week["week_number"]
    assert_not_nil week["workouts"]
    
    workouts = week["workouts"]
    assert_equal 0, workouts["monday"]["distance"]
    assert_equal "Rest", workouts["monday"]["description"]
    assert_equal 5, workouts["tuesday"]["distance"]
    assert_equal "Easy run", workouts["tuesday"]["description"]

    temp_file.unlink
  end

  test "parser should handle errors gracefully" do
    # Test with non-existent file
    parser = TrainingPlanImageParser.new("/non/existent/file")
    result = parser.parse_workouts

    assert_not_nil result[:error]
  end
end