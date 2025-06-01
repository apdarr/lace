require "test_helper"

class CreateEmbeddingsJobTest < ActiveJob::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "Job should update embeddings for all activities" do
    VCR.use_cassette("embeddings_job") do
      CreateEmbeddingsJob.perform_now
      Activity.all.each do |activity|
        assert_not_nil activity.embedding
      end
    end
  end
end
