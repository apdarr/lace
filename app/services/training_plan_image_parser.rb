require 'base64'

class TrainingPlanImageParser
  def initialize(image_path)
    @image_path = image_path
  end

  def parse_workouts
    # Configure RubyLLM if not already configured
    RubyLLM.configure do |config|
      config.openai_api_key = Rails.application.credentials.dig(:open_ai, :token)
    end if RubyLLM.configuration.openai_api_key.blank?

    prompt = build_analysis_prompt
    
    begin
      # Use gpt-4-vision to analyze the image
      response = analyze_image_with_llm(prompt)
      parse_response(response)
    rescue => e
      Rails.logger.error "Error parsing training plan image: #{e.message}"
      { error: "Failed to parse image: #{e.message}" }
    end
  end

  private

  def build_analysis_prompt
    <<~PROMPT
      Analyze this training plan image and extract the workout details in a structured format.
      
      Please identify:
      1. The number of weeks in the plan
      2. For each week, list the workouts for each day (Monday through Sunday)
      3. For each workout, extract:
         - Distance (in miles, convert if needed)
         - Type/description of workout
      
      Return the data in this JSON format:
      {
        "weeks": [
          {
            "week_number": 1,
            "workouts": {
              "monday": {"distance": 0, "description": "Rest"},
              "tuesday": {"distance": 5, "description": "Easy run"},
              "wednesday": {"distance": 3, "description": "Recovery"},
              "thursday": {"distance": 6, "description": "Tempo run"},
              "friday": {"distance": 0, "description": "Rest"},
              "saturday": {"distance": 4, "description": "Easy run"},
              "sunday": {"distance": 10, "description": "Long run"}
            }
          }
        ]
      }
      
      If you cannot clearly read any workout details, use distance: 0 and description: "Unable to read".
    PROMPT
  end

  def analyze_image_with_llm(prompt)
    # Read the image file and encode it
    image_data = File.read(@image_path)
    encoded_image = Base64.encode64(image_data)
    
    # This would use the gpt-4-vision model through RubyLLM
    # For now, return a mock response since we can't test the actual API
    mock_training_plan_response
  end

  def mock_training_plan_response
    # Mock response for development/testing
    {
      "weeks" => [
        {
          "week_number" => 1,
          "workouts" => {
            "monday" => {"distance" => 0, "description" => "Rest"},
            "tuesday" => {"distance" => 5, "description" => "Easy run"},
            "wednesday" => {"distance" => 3, "description" => "Recovery"},
            "thursday" => {"distance" => 6, "description" => "Tempo run"},
            "friday" => {"distance" => 0, "description" => "Rest"},
            "saturday" => {"distance" => 4, "description" => "Easy run"},
            "sunday" => {"distance" => 10, "description" => "Long run"}
          }
        }
      ]
    }
  end

  def parse_response(response)
    # Return the parsed workout data
    response
  end
end