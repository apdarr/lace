class Activity < ApplicationRecord
  has_neighbors :embedding, dimensions: 7
end
