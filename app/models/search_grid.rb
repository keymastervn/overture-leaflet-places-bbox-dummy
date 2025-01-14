# frozen_string_literal: true

class SearchGrid < ApplicationRecord
  after_initialize :set_random_hex_color, if: :new_record?

  scope :with_place_type, ->(type) { where("'#{type}' = ANY (place_types)") }

  STATUSES = [
    PROCESSING = :processing,
    FINISHED = :finished,
    BECOMING_PARENT = :becoming_parent,
    RETRYING = :retrying,
    FAILED = :failed
  ].freeze

  enum status: { PROCESSING => 'processing', FINISHED => 'finished', BECOMING_PARENT => 'becoming_parent', RETRYING => 'retrying', FAILED => 'failed' }

  # Utility methods
  def bounds
    [
      [sw_lat, sw_lng],
      [ne_lat, ne_lng]
    ]
  end

  def center
    [center_lat, center_lng]
  end

  # Utility Methods
  def set_random_hex_color
    self.hex_color = generate_random_hex_color if hex_color.blank?
  end

  def within_division?(division)
    factory = RGeo::Geographic.spherical_factory(srid: 4326)

    grid_polygon = factory.polygon(factory.linear_ring([
      factory.point(sw_lng, sw_lat),
      factory.point(ne_lng, sw_lat),
      factory.point(ne_lng, ne_lat),
      factory.point(sw_lng, ne_lat),
      factory.point(sw_lng, sw_lat) # Close the polygon
    ]))

    division.geometries.contains?(grid_polygon)
  end

  private

  def generate_random_hex_color
    format("#%06x", rand(0..0xFFFFFF))
  end
end
