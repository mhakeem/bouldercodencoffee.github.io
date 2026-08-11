# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../script/generate_event"

class GenerateEventSelectionTest < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@tmp_dir)
  end

  def test_find_event_for_date_matches_on_exact_date
    events = [
      {"date" => "2026-08-19", "location" => "The Rayback"},
      {"date" => "2026-08-26", "location" => "The Rayback"}
    ]

    assert_equal "The Rayback", find_event_for_date(events, "2026-08-26")["location"]
  end

  def test_find_event_for_date_returns_nil_when_no_entry_matches
    events = [{"date" => "2026-08-19", "location" => "The Rayback"}]

    assert_nil find_event_for_date(events, "2026-08-26")
  end

  def test_validate_event_dates_accepts_well_formed_iso8601_dates
    events = [{"date" => "2026-08-19", "location" => "The Rayback"}]

    validate_event_dates!(events)
  end

  def test_validate_event_dates_raises_on_unpadded_date
    events = [{"date" => "2026-8-19", "location" => "The Rayback"}]

    error = assert_raises(RuntimeError) { validate_event_dates!(events) }
    assert_includes error.message, "2026-8-19"
    assert_includes error.message, "The Rayback"
  end

  def test_validate_event_dates_raises_on_non_iso_format
    events = [{"date" => "08/19/2026", "location" => "The Rayback"}]

    error = assert_raises(RuntimeError) { validate_event_dates!(events) }
    assert_includes error.message, "08/19/2026"
  end

  def test_validate_event_dates_raises_on_missing_date
    events = [{"location" => "The Rayback"}]

    error = assert_raises(RuntimeError) { validate_event_dates!(events) }
    assert_includes error.message, "The Rayback"
  end
end

class GenerateEventSkipTest < Minitest::Test
  def test_page_title_for_skip_entry_includes_reason
    title = page_title({"skip" => true, "location" => "The Rayback", "reason" => "Thanksgiving"})

    assert_equal "No Meetup This Week (Thanksgiving)", title
  end

  def test_page_title_for_skip_entry_without_reason
    title = page_title({"skip" => true, "location" => "The Rayback"})

    assert_equal "No Meetup This Week", title
  end

  def test_page_title_for_normal_entry_is_the_location
    title = page_title({"location" => "The Rayback"})

    assert_equal "The Rayback", title
  end
end

class GenerateEventBuildInputTest < Minitest::Test
  def locations
    {"The Rayback" => {"website" => "https://www.therayback.com/"}}
  end

  def test_build_event_details_marks_skip_entries_as_cancelled_with_their_reason
    entry = {"date" => "2026-12-30", "location" => "The Rayback", "skip" => true, "reason" => "New Year's week"}

    input = build_event_details(entry, locations)

    assert_predicate input, :cancelled?
    assert_equal "New Year's week", input.cancellation_reason
  end

  def test_build_event_details_for_a_normal_entry_is_not_cancelled
    entry = {"date" => "2026-08-19", "location" => "The Rayback"}

    input = build_event_details(entry, locations)

    refute_predicate input, :cancelled?
  end

  def test_build_event_details_skips_webcal_lookup_for_a_cancelled_entry
    entry = {"date" => "2026-12-30", "location" => "The Rayback", "skip" => true}
    locations_with_webcal = {
      "The Rayback" => {"website" => "https://www.therayback.com/", "webcal" => "webcal://example.com/feed.ics"}
    }

    breakfast, lunch = build_event_details(entry, locations_with_webcal).found_events

    refute_predicate breakfast, :found?
    refute_predicate lunch, :found?
  end
end
