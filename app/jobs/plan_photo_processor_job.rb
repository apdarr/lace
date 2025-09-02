class PlanPhotoProcessorJob < ApplicationJob
  queue_as :default

  def perform(plan)
    return unless plan.photos.attached?

    plan.photos.each do |photo|
      begin
        process_single_photo(plan, photo)
      rescue => e
        Rails.logger.error "PlanPhotoProcessorJob: Error processing photo #{photo.id}: #{e.message}"
        # Continue with other photos even if one fails
      end
    end
  end

  private

  def process_single_photo(plan, photo)
    # Create a base64 encoded version of the image for GPT
    image_data = photo.download
    base64_image = Base64.strict_encode64(image_data)

    client = OpenAI::Client.new

    response = client.chat(
      parameters: {
        model: "gpt-4-vision-preview",
        messages: [
          {
            role: "system",
            content: system_prompt_for_workout_extraction
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: "Please analyze this training plan image and extract the workout details in the specified JSON format."
              },
              {
                type: "image_url",
                image_url: {
                  url: "data:image/jpeg;base64,#{base64_image}"
                }
              }
            ]
          }
        ],
        temperature: 0.1
      }
    )

    result = response.dig("choices", 0, "message", "content").strip
    Rails.logger.debug "PlanPhotoProcessorJob: GPT response: #{result}"

    # Parse the JSON response and create activities
    begin
      workouts = JSON.parse(result)
      
      if workouts["error"]
        Rails.logger.warn "PlanPhotoProcessorJob: GPT couldn't parse image: #{workouts['error']}"
        return
      end
      
      create_activities_from_workouts(plan, workouts)
    rescue JSON::ParserError => e
      Rails.logger.error "PlanPhotoProcessorJob: Failed to parse GPT response as JSON: #{e.message}"
      Rails.logger.error "PlanPhotoProcessorJob: GPT response was: #{result}"
    end
  end

  def create_activities_from_workouts(plan, workouts)
    return unless workouts.is_a?(Hash) && workouts["weeks"]

    start_date = (plan.race_date - plan.length.weeks).beginning_of_week(:monday)
    current_date = start_date

    workouts["weeks"].each do |week|
      next unless week["days"]
      
      week["days"].each do |day|
        Activity.create(
          plan_id: plan.id,
          distance: day["distance"].to_f,
          description: day["description"] || "Workout",
          start_date_local: current_date
        )
        current_date += 1.day
      end
    end
  end

  def system_prompt_for_workout_extraction
    <<~PROMPT
      You are an expert running coach and training plan analyzer. Your task is to analyze images of training plans and extract workout details.

      Please extract the following information from the training plan image:
      - Week-by-week workout schedule
      - Daily activities with distances and descriptions
      - Training intensities and workout types

      Return the data in this exact JSON format:
      {
        "weeks": [
          {
            "week_number": 1,
            "days": [
              {
                "day": "monday",
                "distance": 5.0,
                "description": "Easy run"
              },
              {
                "day": "tuesday", 
                "distance": 0,
                "description": "Rest day"
              }
              // ... continue for all 7 days
            ]
          }
          // ... continue for all weeks in the plan
        ]
      }

      Guidelines:
      - Set distance to 0 for rest days or cross-training days
      - Use clear, concise descriptions for workouts
      - Include workout intensity when specified (e.g., "Tempo run", "Easy run", "Intervals")
      - If distances are given in kilometers, convert to miles
      - If the image is unclear or doesn't contain a training plan, return {"error": "Unable to parse training plan from image"}

      RESPONSE FORMAT:
      Return ONLY valid JSON with no extra text or explanations.
    PROMPT
  end
end
