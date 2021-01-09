class BackendService
  def self.conn
    Faraday.new(url: ENV["BACKEND_URL"])
  end

  def self.flights_search(query)
    response = conn.get('/flight_search') do |req|
      req.params[:departure_airport] = query[:departure_airport]
      req.params[:departure_date] = query[:departure_date]
      req.params[:trip_duration] = query[:trip_duration]
    end
    JSON.parse(response.body, symbolize_names: true)
  end
end
