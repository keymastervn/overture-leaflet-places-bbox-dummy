# frozen_string_literal: true

class PlacesController < ApplicationController
  def index
    sw_lat = params[:sw_lat].to_f
    sw_lng = params[:sw_lng].to_f
    ne_lat = params[:ne_lat].to_f
    ne_lng = params[:ne_lng].to_f

    @places = Place.where(latitude: sw_lat..ne_lat, longitude: sw_lng..ne_lng).limit(500)

    # Render the places as JSON
    render json: @places.to_json(only: [:id, :name, :latitude, :longitude, :addresses])
  end
end
