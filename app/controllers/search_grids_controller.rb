# frozen_string_literal: true

class SearchGridsController < ApplicationController
  def index
    center_lat = params[:center_lat].to_f
    center_lng = params[:center_lng].to_f
    radius = params[:radius].to_f || 5000 # meters

    center_point = "SRID=4326;POINT(#{center_lng} #{center_lat})"

    @search_grids = SearchGrid.where(
      "ST_DWithin(geography(ST_MakePoint(center_lng, center_lat)), geography(ST_MakePoint(?, ?)), ?)",
      center_lng, center_lat, radius
    ).where(status: :finished, is_land: true).limit(100_000)

    # @search_grids = SearchGrid.where(status: :finished)

    render json: @search_grids.as_json(only: [
      :id, :sw_lat, :sw_lng, :ne_lat, :ne_lng, :center_lat, :center_lng, :radius, :hex_color, :place_types, :place_results, :postcode
    ])
  end

  # GET /search_grids/:id
  def show
    @search_grid = SearchGrid.find(params[:id])

    render json: @search_grid.as_json(only: [
      :id, :sw_lat, :sw_lng, :ne_lat, :ne_lng, :center_lat, :center_lng, :radius, :hex_color, :place_types, :place_results, :postcode
    ])
  end
end
