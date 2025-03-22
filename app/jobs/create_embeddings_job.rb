class CreateEmbeddingsJob < ApplicationJob
  queue_as :default

  def perform(query = nil)
    if query.present?
      # Create embeddings for the query, only if the query is not empty
      create_query_embeddings(query)
    else
      # Otherwise, create embeddings for all activities
      create_embeddings
    end
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
        Rails.logger.error "Failed to create embeddings for activity #{activity.id}: #{e.message}"
        raise
      end
    end

    def format_input(activity)
      "Distance: #{activity.distance}, Elapsed Time: #{activity.elapsed_time}, Kudos Count: #{activity.kudos_count}, Activity Type: #{activity.activity_type}, Average Heart Rate: #{activity.average_heart_rate}, Max Heart Rate: #{activity.max_heart_rate}"
    end

    def create_query_embeddings(query)
      # I know duplicating the API call is bad practice, but want to get it working first
      begin
        client = OpenAI::Client.new(access_token: ENV["OPENAI_TOKEN"])

        response = client.embeddings(
          parameters: {
            model: "text-embedding-3-small",
            input: query
          }
        )
      response.dig("data", 0, "embedding")
      rescue StandardError => e
        Rails.logger.error "Failed to create query embeddings: #{e.message}"
        raise
      end
    end
end
