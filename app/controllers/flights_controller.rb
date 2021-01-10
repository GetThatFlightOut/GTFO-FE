class FlightsController < ApplicationController
  def show
    @trip = Rails.cache.read(params[:id]) or not_found
  end

  def index
    @trips = SearchFacade.get_flights(flight_params)
  end

  private
  def flight_params
    params.permit(:departure_airport, :departure_date, :trip_duration)
  end
end
