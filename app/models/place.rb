# frozen_string_literal: true

class Place < ApplicationRecord
  attribute :geopoint, :st_point, srid: 4326, geographic: true

  scope :by_primary_category, ->(category) { where(primary_categories: category) }

  # Scope for filtering by alternate categories
  scope :by_alternate_category, ->(category) { where("'#{category}' = ANY (alternate_categories)") }
end
