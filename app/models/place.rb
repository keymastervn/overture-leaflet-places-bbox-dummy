# frozen_string_literal: true

class Place < ApplicationRecord
  scope :by_primary_category, ->(category) { where(primary_categories: category) }

  # Scope for filtering by alternate categories
  scope :by_alternate_category, ->(category) { where("'#{category}' = ANY (alternate_categories)") }
end
