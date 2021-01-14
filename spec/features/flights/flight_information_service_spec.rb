require 'rails_helper'

describe 'flight service' do
  it 'will return trip results for search locations' do
    json1 = File.read('spec/fixtures/request_id_return.json')
    json2 = File.read('spec/fixtures/flights.json')
    query = '?departure_airport=DEN&departure_date=30/01/2021&limit=20&trip_duration=3&uid'
    json1_parsed = JSON.parse(json1, symbolize_names: true)

    if ENV['WEBMOCK'] == 'true'
      stub_request(:get, "#{ENV['BACKEND_URL']}/api/v1/search#{query}")
        .to_return(status: 200, body: json1, headers: {})
    end

    if ENV['WEBMOCK'] == 'true'
      stub_request(:get, "#{ENV['BACKEND_URL']}/api/v1/requests/#{json1_parsed[:data][:request_id]}")
        .to_return(status: 200, body: json2, headers: {})
    end

    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(true)

    visit '/'
    select 'Denver International', from: 'departure_airport'
    fill_in 'departure_date', with: '2021-01-30'
    fill_in 'trip_duration', with: 3
    click_button('Search Locations')

    expect(page).to have_current_path(flights_requests_path(json1_parsed[:data][:request_id]), ignore_query: true)

    expect(page).to have_css('.Flight', count: 20)

    within(first('.Flight')) do
      expect(page).to have_css('.DestinationCity')
      expect(page).to have_css('.Price')
      expect(page).to have_css('.weather-text')
      expect(page).to have_css('.Weather_img')
    end

    within(:xpath, '(//tr[@class="Flight"])[last()]') do
      expect(page).to have_css('.DestinationCity')
      expect(page).to have_css('.Price')
      expect(page).to have_css('.weather-text')
      expect(page).to have_css('.Weather_img')
    end
  end

  it 'will return a trip results for lucky locations' do
    json_data = File.read('spec/fixtures/flights.json')
    @flights_data = JSON.parse(json_data, symbolize_names: true)
    flight_json = {data: [@flights_data[:data][0]]}.to_json

    query = '?departure_airport=DEN&departure_date=30/01/2021&trip_duration=3&limit=1'

    if ENV['WEBMOCK'] == 'true'
      stub_request(:get, "#{ENV['BACKEND_URL']}/api/v1/search#{query}")
      .to_return(status: 200, body: flight_json, headers: {})
    end

    visit '/'

    select 'Denver International', from: 'departure_airport'
    fill_in 'departure_date', with: '2021-01-30'
    fill_in 'trip_duration', with: 3
    click_button('Lucky Location')

    expect(current_path).to eq(flight_show_path('777'))

    expect(page).to have_content('Las Vegas')
  end

  it 'returns error when too far out date given' do
    json = File.read('./spec/fixtures/flight_data_bad_date.json')
    query = '?departure_airport=DEN&departure_date=30/01/2028&limit=20&trip_duration=3'

    if ENV['WEBMOCK'] == 'true'
      stub_request(:get, "#{ENV['BACKEND_URL']}/api/v1/search#{query}")
        .to_return(status: 200, body: json, headers: {})
    end
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(true)

    visit '/'

    fill_in 'departure_date', with: '2028-01-30'
    fill_in 'trip_duration', with: 3

    click_button('Search Locations')

    expect(page).to have_current_path(root_path)

    expect(page).to have_css('.error')

    within '.error' do
      expect(page).to have_content('Departure date too far in the future')
    end
  end

  it 'returns error when no flights returned' do
    json = File.read('./spec/fixtures/flight_data_no_flights.json')
    query = '?departure_airport=DEN&departure_date=30/01/2021&limit=20&trip_duration=3'
    if ENV['WEBMOCK'] == 'true'
      stub_request(:get, "#{ENV['BACKEND_URL']}/api/v1/search#{query}")
        .to_return(status: 200, body: json, headers: {})
    end

    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(true)

    visit '/'

    fill_in 'departure_date', with: '2021-01-30'
    fill_in 'trip_duration', with: 3

    click_button('Search Locations')

    expect(page).to have_current_path(root_path)

    expect(page).to have_css('.error')

    within '.error' do
      expect(page).to have_content('No flights match criteria')
    end
  end

  it 'will render trips grouped by weather' do
    json = File.read('spec/fixtures/flights.json')
    #json = File.read('./spec/fixtures/flight_data_return.json')
    query = '?departure_airport=DEN&departure_date=30/01/2021&limit=20&trip_duration=3'
    if ENV['WEBMOCK'] == 'true'
      stub_request(:get, "#{ENV['BACKEND_URL']}/api/v1/search#{query}")
        .to_return(status: 200, body: json, headers: {})
    end

    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(true)

    visit '/'

    fill_in 'departure_date', with: '2021-01-30'
    fill_in 'trip_duration', with: 3

    click_button('Search Locations')

    expect(page).to_not have_css(".hot-trips")


    expect(page).to_not have_css(".warm-trips")

    within ".cool-trips" do
      expect(page).to have_content("Los Angeles")
      expect(page).to have_content("Feels Like: 54.9")
    end

    within ".cold-trips" do
      expect(page).to have_content("Washington, D.C.")
      expect(page).to have_content("Feels Like: 43.7")

      expect(page).to have_content("Salt Lake City")
      expect(page).to have_content("Feels Like: 34.8")
    end
  end
end
