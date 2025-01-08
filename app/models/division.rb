# frozen_string_literal: true

class Division < ApplicationRecord
  FACTORY = RGeo::Geographic.spherical_factory(srid: 4326)

  validates :subtype, presence: true, inclusion: { in: %w[region country county] }
  validates :division_type, presence: true, inclusion: { in: %w[division_area division_boundary] }
  validates :division_class, presence: true, inclusion: { in: %w[land maritime] }
  validates :division_id, presence: true, uniqueness: true
  validates :geometries, presence: true

  # Scope for filtering based on division_class
  scope :land_divisions, -> { where(division_class: 'land') }
  scope :maritime_divisions, -> { where(division_class: 'maritime') }

  # Example helper method to check if a geometry overlaps another
  def overlaps?(geometry)
    Division.where("ST_Intersects(geometries, ?)", geometry).exists?
  end

  def contains_grid?(grid)
    division_geom = geometries
    grid_geom = FACTORY.polygon(FACTORY.linear_ring([
      FACTORY.point(grid.sw_lng, grid.sw_lat),
      FACTORY.point(grid.ne_lng, grid.sw_lat),
      FACTORY.point(grid.ne_lng, grid.ne_lat),
      FACTORY.point(grid.sw_lng, grid.ne_lat),
      FACTORY.point(grid.sw_lng, grid.sw_lat)
    ]))

    division_geom.contains?(grid_geom)
  end
end
