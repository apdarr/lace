class CreateEmbeddingsJob < ApplicationJob
  queue_as :default

  def perform
    # Do something later
    create_embeddings
  end

  private
    def create_embeddings
      begin
        client = OpenAI::Client.new(access_token: ENV["OPENAI_TOKEN"])

        activities = Activity.all
        activities.each do |activity|
          input = format_input(activity)
          response = client.embeddings(
          parameters: {
            model: "text-embedding-3-small",
            input: input
        })
          vector = response.dig("data", 0, "embedding")
          activity.update!(embedding: vector)
        end
      rescue StandardError => e
        Rails.logger.error "Failed to create embeddings: #{e.message}"
        raise
      end
    end

    def format_input(activity)
      "Distance: #{activity.distance}, Elapsed Time: #{activity.elapsed_time}, Kudos Count: #{activity.kudos_count}, Activity Type: #{activity.activity_type}, Average Heart Rate: #{activity.average_heart_rate}, Max Heart Rate: #{activity.max_heart_rate}"
    end
end
