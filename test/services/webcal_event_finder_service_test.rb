# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../script/services/webcal_event_finder_service"

class WebcalEventFinderServiceTest < Minitest::Test
  def setup
    fixture_path = File.join(__dir__, "..", "fixtures", "rayback_food_trucks.ics")
    stub_request(:get, "http://example.com/cal.ics").to_return(status: 200, body: File.read(fixture_path))
    @service = WebcalEventFinderService.new("webcal://example.com/cal.ics")
  end

  def test_raises_webcal_fetching_error_on_a_non_success_response
    stub_request(:get, "http://example.com/cal.ics").to_return(status: 500)

    assert_raises(WebcalEventFinderService::WebcalFetchingError) do
      WebcalEventFinderService.new("webcal://example.com/cal.ics")
    end
  end

  def test_downloads_and_parses_the_ics_feed_on_a_success_response
    assert_equal 9, @service.calendar.events.size
  end

  def test_search_events_finds_real_breakfast_and_lunch_pair_on_same_day
    morning, noon = @service.search_events(Date.new(2025, 3, 27))

    assert morning.found?
    assert_equal "Rollin in Daisies", morning.summary
    assert noon.found?
    assert_equal "Arepas Caribbean", noon.summary
  end

  def test_html_is_stripped_from_description
    _morning, noon = @service.search_events(Date.new(2026, 8, 11))

    assert noon.found?
    refute_match(/<\/?[^>]+>/, noon.description)
    assert_includes noon.description, "Denver's first Indian Fusion"
  end

  def test_nothing_found_on_a_date_with_no_events_in_the_feed
    morning, noon = @service.search_events(Date.new(2025, 3, 28))

    refute morning.found?
    refute noon.found?
  end

  def test_event_exists_with_no_breakfast_and_lunch
    # La Rue Bayou runs 4pm-8pm Mountain on 2026-08-06 - present in the feed,
    # but not at 8am, 9am, or noon, so both slots should come back not-found.
    morning, noon = @service.search_events(Date.new(2026, 8, 6))

    refute morning.found?
    refute noon.found?
  end

  def test_breakfast_search_matches_9am
    morning, = @service.search_events(Date.new(2026, 4, 1))

    assert morning.found?
    assert_equal "9am Truck", morning.summary
  end

  def test_breakfast_search_matches_8am
    morning, = @service.search_events(Date.new(2026, 4, 22))

    assert morning.found?
    assert_equal "8am Truck", morning.summary
  end

  def test_range_boundary_includes_event_at_end_of_day_and_excludes_one_second_past
    events_in_range = @service.send(:events_in_range, Date.new(2026, 4, 15), Date.new(2026, 4, 15))

    assert_includes events_in_range.map(&:summary), "Just In Time"
    refute_includes events_in_range.map(&:summary), "Too Late"
  end

  def test_missing_description_does_not_raise
    morning, = @service.search_events(Date.new(2026, 4, 8))

    assert morning.found?
    assert_equal "No Description Truck", morning.summary
    assert_nil morning.description
  end
end
