# frozen_string_literal: true

class PlacesController < ApplicationController
  def index
    center_lat = params[:center_lat].to_f
    center_lng = params[:center_lng].to_f
    radius = params[:radius].to_f || 5000 # meters

    # Ensure geographic calculations use the correct format (SRID 4326)
    center_point = "SRID=4326;POINT(#{center_lng} #{center_lat})"

    @places = Place.where(
      "ST_DWithin(geopoint, ST_GeogFromText(?), ?)",
      center_point,
      radius
    ).limit(30000)

    # Render the places as JSON
    render json: @places.to_json(only: [:id, :name, :latitude, :longitude, :addresses])
  end
end
