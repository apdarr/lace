class Activity < ApplicationRecord
  has_neighbors :embedding, dimensions: 3

  def self.create_embeddings
    # Create an embedding for all activities
  end
end
