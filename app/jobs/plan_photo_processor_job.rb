class PlanPhotoProcessorJob < ApplicationJob
  queue_as :default

  # Entry point from ActiveJob
  def perform(plan)
    plan.update!(processing_status: "processing")
    puts "🔍 PlanPhotoProcessorJob: starting for plan #{plan.id} (#{plan.photos.count} photos)"
    Rails.logger.info "PlanPhotoProcessorJob: starting for plan #{plan.id} (#{plan.photos.count} photos)"
    return unless plan.photos.attached?

    attachments = prepare_attachments(plan)
    puts "🔍 PlanPhotoProcessorJob: prepared #{attachments.size} attachments"
    if attachments.empty?
      puts "⚠️  PlanPhotoProcessorJob: no usable image attachments after conversion"
      Rails.logger.warn "PlanPhotoProcessorJob: no usable image attachments after conversion"
      plan.update!(processing_status: "failed")
      return
    end

    extract_and_persist_workouts(plan, attachments)
    plan.update!(processing_status: "completed")
    puts "✅ PlanPhotoProcessorJob: completed successfully"
  rescue => e
    puts "❌ PlanPhotoProcessorJob: unrecoverable error: #{e.class}: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    Rails.logger.error "PlanPhotoProcessorJob: unrecoverable error: #{e.class}: #{e.message}"
    plan.update!(processing_status: "failed")
  end

  private

  # Convert any HEIC/HEIF images to JPEG so the vision model can read them.
  # Returns an array of ActiveStorage::Blob (original or converted) suitable to pass via RubyLLM `with:`.
  def prepare_attachments(plan)
    blobs = []

    puts "🔍 prepare_attachments: processing #{plan.photos.count} photos"
    plan.photos.each_with_index do |attachment, idx|
      begin
        puts "🔍 Photo #{idx + 1}: #{attachment.filename} (#{attachment.content_type})"
        if attachment.content_type.in?(%w[image/heic image/heif])
          puts "🔍 Photo #{idx + 1}: attempting HEIC->JPEG conversion"
          Rails.logger.info "PlanPhotoProcessorJob: converting HEIC #{attachment.filename} -> JPEG"
          begin
            jpeg_variant = attachment.variant(format: :jpeg).processed
            converted_blob = ActiveStorage::Blob.create_and_upload!(
              io: StringIO.new(jpeg_variant.download),
              filename: attachment.filename.to_s.sub(/\.(heic|heif)\z/i, ".jpg"),
              content_type: "image/jpeg"
            )
            blobs << converted_blob
            puts "✅ Photo #{idx + 1}: converted successfully"
          rescue => conversion_error
            puts "⚠️  Photo #{idx + 1}: conversion failed (#{conversion_error.class}: #{conversion_error.message}), using original"
            Rails.logger.warn "PlanPhotoProcessorJob: HEIC conversion failed (#{conversion_error.message}), using original"
            blobs << attachment.blob
          end
        else
          blobs << attachment.blob
          puts "✅ Photo #{idx + 1}: using original blob"
        end
      rescue => e
        puts "❌ Photo #{idx + 1}: error preparing: #{e.class} - #{e.message}"
        puts e.backtrace.first(3).join("\n")
        Rails.logger.error "PlanPhotoProcessorJob: error preparing #{attachment.filename}: #{e.class} - #{e.message}"
        Rails.logger.error e.backtrace.first(3).join("\n")
        # Skip this attachment entirely if we can't even access the blob
      end
    end

    puts "🔍 prepare_attachments: returning #{blobs.size} blobs"
    Rails.logger.info "PlanPhotoProcessorJob: prepared #{blobs.size} blobs from #{plan.photos.count} photos"
    blobs
  end

  # Use RubyLLM simplified API: chat.with_instructions + ask(..., with: attachments)
  def extract_and_persist_workouts(plan, attachments)
    Rails.logger.info "PlanPhotoProcessorJob: invoking RubyLLM with #{attachments.size} image(s)"

    prompt_text = system_prompt_for_workout_extraction
    chat = RubyLLM.chat(model: "gpt-5-mini")

    response = chat.ask(prompt_text, with: attachments)
    unless response && response.content.present?
      Rails.logger.error "PlanPhotoProcessorJob: empty response from RubyLLM"
      return
    end

    raw = response.content.to_s.strip
    Rails.logger.debug "PlanPhotoProcessorJob: raw model output (truncated): #{raw[0, 150]}"

    workouts = parse_json_safely(raw)
    unless workouts
      Rails.logger.error "PlanPhotoProcessorJob: aborting \u2013 could not parse JSON output"
      return
    end

    if workouts.is_a?(Hash) && workouts["error"]
      Rails.logger.warn "PlanPhotoProcessorJob: model reported error: #{workouts['error']}"
      return
    end

    create_activities_from_workouts(plan, workouts)
    Rails.logger.info "PlanPhotoProcessorJob: activities created for plan #{plan.id}"
  rescue RubyLLM::Error => e
    Rails.logger.error "PlanPhotoProcessorJob: RubyLLM API error: #{e.class}: #{e.message}"
  end

  def parse_json_safely(text)
    json_str = text[/\{.*\}\s*\z/m] || text # heuristic: take from first { to end if extra prose
    JSON.parse(json_str)
  rescue JSON::ParserError => e
    Rails.logger.error "PlanPhotoProcessorJob: JSON parse error: #{e.message}"
    nil
  end

  def create_activities_from_workouts(plan, workouts)
    return unless workouts.is_a?(Hash) && workouts["weeks"]

    start_date = (plan.race_date - plan.length.weeks).beginning_of_week(:monday)
    current_date = start_date
    created = 0
    workouts["weeks"].each do |week|
      next unless week["days"]
      week["days"].each do |day|
        distance_val = day["distance"].to_f
        description_val = day["description"].presence || "Workout"
        Activity.create(
          plan_id: plan.id,
          distance: distance_val,
          description: description_val,
          start_date_local: current_date
        )
        current_date += 1.day
        created += 1
      end
    end
    Rails.logger.info "PlanPhotoProcessorJob: created #{created} activities starting #{start_date.to_date}"
  end

  def system_prompt_for_workout_extraction
    File.read(Rails.root.join("app", "jobs", "prompts", "workout_extraction.txt"))
  end
end
