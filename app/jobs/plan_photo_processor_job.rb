class PlanPhotoProcessorJob < ApplicationJob
  queue_as :default

  def perform(plan)
    puts "DEBUG: PlanPhotoProcessorJob starting for plan #{plan.id}"
    Rails.logger.info "PlanPhotoProcessorJob: Starting job for plan #{plan.id}"
    Rails.logger.info "PlanPhotoProcessorJob: Photos attached? #{plan.photos.attached?}"
    Rails.logger.info "PlanPhotoProcessorJob: Number of photos: #{plan.photos.count}"

    return unless plan.photos.attached?

    puts "DEBUG: About to call process_all_photos_combined"
    process_all_photos_combined(plan)
    puts "DEBUG: Finished process_all_photos_combined"
  end

  private

  def process_all_photos_combined(plan)
    puts "DEBUG: Starting process_all_photos_combined with #{plan.photos.count} photos"
    puts "DEBUG: Photos attached? #{plan.photos.attached?}"
    puts "DEBUG: Photos: #{plan.photos.map(&:id)}"
    # Collect all photos as base64 images
    image_data_array = []

    # First pass: convert any HEIC files to JPEG and store them
    converted_photos = []
    plan.photos.each do |photo|
      if photo.content_type == "image/heic" || photo.content_type == "image/heif"
        puts "DEBUG: Converting HEIC/HEIF to JPEG for photo #{photo.id}"
        # Convert HEIC to JPEG using image_processing
        converted_image = photo.variant(format: :jpeg)
        converted_data = converted_image.processed.download

        # Create a new blob with the converted JPEG data
        converted_blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(converted_data),
          filename: "#{File.basename(photo.filename.to_s, '.*')}.jpg",
          content_type: "image/jpeg"
        )

        # Attach the converted blob to the plan
        plan.photos.attach(converted_blob)
        converted_photos << plan.photos.last
        puts "DEBUG: Converted photo #{photo.id} to JPEG as attachment #{plan.photos.last.id}"
      else
        # Keep non-HEIC photos as-is
        converted_photos << photo
      end
    end

    # Second pass: process all photos (now all in supported formats)
    converted_photos.each do |photo|
      begin
        puts "DEBUG: Processing photo #{photo.id}, filename: #{photo.filename}, content_type: #{photo.content_type}"
        puts "DEBUG: Photo blob present? #{photo.blob.present?}"
        puts "DEBUG: Photo blob key: #{photo.blob&.key}"

        image_data = photo.download
        puts "DEBUG: Image size: #{image_data.size} bytes"
        puts "DEBUG: Image dimensions info would require image analysis"

        base64_image = Base64.strict_encode64(image_data)
        puts "DEBUG: Base64 encoded size: #{base64_image.length} characters"
        image_data_array << base64_image
        puts "DEBUG: Successfully encoded photo #{photo.id}"
      rescue => e
        puts "DEBUG: Error processing photo #{photo.id}: #{e.message}"
        puts "DEBUG: Error class: #{e.class}"
        puts "DEBUG: Backtrace: #{e.backtrace.first(3).join("\n")}"
        Rails.logger.error "PlanPhotoProcessorJob: Error processing photo #{photo.id}: #{e.message}"
        # Continue with other photos even if one fails
      end
    end

    if image_data_array.empty?
      puts "DEBUG: No images to process"
      Rails.logger.warn "PlanPhotoProcessorJob: No images to process"
      return
    end

    puts "DEBUG: About to create OpenAI client"
    client = OpenAI::Client.new
    puts "DEBUG: OpenAI client created, about to make API call"

    # Build content array with text instruction and all images
    content_array = [
      {
        type: "text",
        text: if image_data_array.size == 1
                "Please analyze this training plan image and extract the workout details in the specified JSON format."
              else
                "Please analyze ALL provided training plan images (these represent sequential pages of one training plan) and extract the unified workout details in the specified JSON format."
              end
      }
    ]

    # Add all images to the content array
    image_data_array.each do |base64_image|
      content_array << {
        type: "image_url",
        image_url: {
          url: "data:image/jpeg;base64,#{base64_image}"
        }
      }
    end

    puts "DEBUG: Making OpenAI API call with model gpt-5-nano-2025-08-07"
    response = client.chat(
      parameters: {
        model: "gpt-5-nano-2025-08-07",
        messages: [
          {
            role: "system",
            content: system_prompt_for_workout_extraction
          },
          {
            role: "user",
            content: content_array
          }
        ]
      }
    )

    puts "DEBUG: Received OpenAI response"
    result = response.dig("choices", 0, "message", "content").to_s.strip
    puts "DEBUG: GPT response (first 100 chars): #{result[0..100]}"
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
    File.read(Rails.root.join("app", "jobs", "prompts", "workout_extraction.txt"))
  end
end
