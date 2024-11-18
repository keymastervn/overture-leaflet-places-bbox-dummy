# frozen_string_literal: true

class SearchGridsController < ApplicationController
  def index
    @search_grids = SearchGrid.all
    render json: @search_grids.as_json(only: [:id, :sw_lat, :sw_lng, :ne_lat, :ne_lng, :center_lat, :center_lng, :radius, :hex_color, :place_types])
  end

  # GET /search_grids/:id
  def show
    @search_grid = SearchGrid.find(params[:id])
    render json: @search_grid.as_json(only: [:id, :sw_lat, :sw_lng, :ne_lat, :ne_lng, :center_lat, :center_lng, :radius, :hex_color, :place_types])
  end
end
