require 'rails_helper'

describe 'flight service' do
  it 'will return flight data' do
    json = File.read('./spec/fixtures/flight_data_return.json')
    query = "?departure_airport=DEN&departure_date=2021/01/30&trip_duration=3&limit=20"

    stub_request(:get, "#{ENV["BACKEND_URL"]}/api/v1/search#{query}").
            to_return(status: 200, body: json, headers: {})

    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(true)

    visit '/'

    select 'Denver International', from: 'departure_airport'
    fill_in 'departure_date', with: '2021/01/30'
    fill_in 'trip_duration', with: 3
    click_button('Search Locations')
    expect(page).to have_current_path(flights_path, ignore_query: true)

    expect(page).to have_css('.Flight', count: 5)

    within(first('.Flight')) do
      expect(page).to have_css('.DestinationCity')
      expect(page).to have_css('.Price')
      expect(page).to have_css('.Duration')
      expect(page).to have_css('.Weather')
    end

    within(:xpath, '(//tr[@class="Flight"])[last()]') do
      expect(page).to have_css('.DestinationCity')
      expect(page).to have_css('.Price')
      expect(page).to have_css('.Duration')
      expect(page).to have_css('.Weather')
    end
  end

  it 'returns error when too far out date given' do
    json = File.read('./spec/fixtures/flight_data_bad_date.json')
    query = '?departure_airport=DEN&departure_date=2021/01/30&trip_duration=3'

    stub_request(:get, 'http:///api/v1/search?departure_airport=DEN&departure_date=01/30/2028&trip_duration=3')
      .to_return(status: 200, body: json, headers: {})

    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(true)

    visit '/'

    fill_in 'departure_date', with: '01/30/2028'
    fill_in 'trip_duration', with: 3
    save_and_open_page

    click_button('Search Locations')

    expect(page).to have_current_path(root_path)

    expect(page).to have_css('search-error')

    within '.search-error' do
      expect(page).to have_content('Departure date too far in the future')
    end
  end
end