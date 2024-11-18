# frozen_string_literal: true

class SearchGrid < ApplicationRecord
  after_initialize :set_random_hex_color, if: :new_record?

  scope :with_place_type, ->(type) { where("'#{type}' = ANY (place_types)") }

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

  private

  def generate_random_hex_color
    format("#%06x", rand(0..0xFFFFFF))
  end
end
