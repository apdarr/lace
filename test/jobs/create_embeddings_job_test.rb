require "test_helper"

class CreateEmbeddingsJobTest < ActiveJob::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "Job should create one-off embedding from the search" do
    search_query = "activities where my heart rate was over 150"

    VCR.use_cassette("search_query") do
      embedding = CreateEmbeddingsJob.perform_now(search_query)
      # OpenAI's text-embedding-3-small model returns 1536-dimensional vectors
      assert_equal 1536, embedding.length

      # All values should be floating point numbers
      assert embedding.all? { |value| value.is_a?(Float) }

      # Embedding vectors should have values roughly in the range of -1 to 1
      assert embedding.all? { |value| value.between?(-1, 1) }
    end
  end

  test "Job should update embeddings for all activities" do
    VCR.use_cassette("embeddings_job") do
      CreateEmbeddingsJob.perform_now
      Activity.all.each do |activity|
        assert_not_nil activity.embedding
      end
    end
  end
end
