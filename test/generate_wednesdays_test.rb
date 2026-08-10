# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../script/generate_wednesdays"

class GenerateWednesdaysTest < Minitest::Test
  def setup
    @tmp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@tmp_dir)
  end

  def test_start_date_is_the_wednesday_after_the_last_existing_entry
    events = [{"date" => "2026-08-19", "location" => "The Rayback"}]

    assert_equal Date.new(2026, 8, 26), start_date(events)
  end

  def test_start_date_bootstraps_from_today_when_events_are_empty
    assert_equal Date.new(2026, 8, 19), start_date([], today: Date.new(2026, 8, 18))
  end

  def test_start_date_bootstraps_from_today_when_today_is_a_wednesday
    assert_equal Date.new(2026, 8, 19), start_date([], today: Date.new(2026, 8, 19))
  end

  def test_generate_dates_through_an_end_date
    dates = generate_dates(Date.new(2026, 8, 19), through: Date.new(2026, 9, 2))

    assert_equal [Date.new(2026, 8, 19), Date.new(2026, 8, 26), Date.new(2026, 9, 2)], dates
  end

  def test_generate_dates_through_excludes_dates_past_the_end
    dates = generate_dates(Date.new(2026, 8, 19), through: Date.new(2026, 8, 25))

    assert_equal [Date.new(2026, 8, 19)], dates
  end

  def test_generate_dates_for_a_number_of_weeks
    dates = generate_dates(Date.new(2026, 8, 19), weeks: 3)

    assert_equal [Date.new(2026, 8, 19), Date.new(2026, 8, 26), Date.new(2026, 9, 2)], dates
  end

  def test_default_location_uses_the_single_entry
    assert_equal "The Rayback", default_location({"The Rayback" => {}})
  end

  def test_default_location_raises_when_no_locations_exist
    error = assert_raises(RuntimeError) { default_location({}) }
    assert_includes error.message, "No locations found"
  end

  def test_default_location_raises_when_multiple_locations_exist
    error = assert_raises(RuntimeError) { default_location({"The Rayback" => {}, "Sanitas" => {}}) }
    assert_includes error.message, "Multiple locations"
    assert_includes error.message, "The Rayback"
    assert_includes error.message, "Sanitas"
  end

  def test_append_entries_preserves_existing_content_and_appends_new_entries
    path = File.join(@tmp_dir, "events.yml")
    File.write(path, <<~YAML)
      ---
      # Header comment.
      events:
        - date: "2026-08-19"
          location: "The Rayback"
          highlight: "Existing entry, untouched"
    YAML

    append_entries([Date.new(2026, 8, 26), Date.new(2026, 9, 2)], "The Rayback", path: path)

    result = YAML.load_file(path)
    assert_includes File.read(path), "# Header comment."
    assert_equal 3, result["events"].size
    assert_equal "Existing entry, untouched", result["events"][0]["highlight"]
    assert_equal "2026-08-26", result["events"][1]["date"]
    assert_equal "The Rayback", result["events"][1]["location"]
    assert_equal "2026-09-02", result["events"][2]["date"]
  end

  def test_append_entries_creates_the_file_when_it_does_not_exist
    path = File.join(@tmp_dir, "events.yml")

    append_entries([Date.new(2026, 8, 19)], "The Rayback", path: path)

    result = YAML.load_file(path)
    assert_equal [{"date" => "2026-08-19", "location" => "The Rayback"}], result["events"]
  end
end
