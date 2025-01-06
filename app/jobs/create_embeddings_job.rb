class CreateEmbeddingsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    create_embeddings
  end

  private
    def create_embeddings
      client = OpenAI::Client.new(access_token: ENV["OPENAI_TOKEN"])

      activities = Activity.all
      activities.each do |activity|
        input = format_input(activity)
        response = client.embeddings(
          parameters: {
            model: "text-embedding-3-small",
            input: input
          }
        )
        vector = response.dig("data", 0, "embedding")
        activity.update(embedding: vector)
      end
    end

    def format_input(activity)
      "Distance: #{activity.distance}, Elapsed Time: #{activity.elapsed_time}, Kudos Count: #{activity.kudos_count}, Activity Type: #{activity.activity_type}, Average Heart Rate: #{activity.average_heart_rate}, Max Heart Rate: #{activity.max_heart_rate}"
    end
end
