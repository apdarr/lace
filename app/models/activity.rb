class Activity < ApplicationRecord
  has_neighbors :embedding

  belongs_to :plan, optional: true
end
