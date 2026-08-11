#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates the next event page in src/_events/ from data/social_automation/events.yml.
# Selection is by the upcoming meetup date (next Wednesday), not "earliest pending
# entry" — this avoids generating a page early when a week is skip: true.
#
# Usage: script/generate_event.rb [--mode=pr|direct] [--date=YYYY-MM-DD]

require "bundler/setup"
require "yaml"
require "date"
require "fileutils"
require "optparse"

require_relative "lib/paths"
require_relative "lib/wednesday"
require_relative "value_objects/event_details"
require_relative "services/webcal_event_finder_service"
require_relative "services/content/event_content_service"

# @param text [String]
# @return [String] URL-safe slug
def slugify(text)
  text.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
end

# @param date [String] YYYY-MM-DD
# @param location_name [String]
# @param events_dir [String]
# @return [String] path to the event's markdown file
def event_file_path(date, location_name, events_dir: Paths::EVENTS_DIR)
  File.join(events_dir, "#{date}-#{slugify(location_name)}.md")
end

# @param events [Array<Hash>]
# @param date [String] YYYY-MM-DD
# @return [Hash, nil]
def find_event_for_date(events, date)
  events.find { |e| e["date"] == date }
end

# Validates strict ISO-8601 up front, since Date.parse/Time.parse used
# downstream are lenient and would otherwise let a malformed date silently
# fail to string-match in find_event_for_date and produce a no-op.
#
# @param events [Array<Hash>]
# @raise [RuntimeError] if any entry's date isn't valid ISO-8601
def validate_event_dates!(events)
  events.each do |entry|
    Date.iso8601(entry["date"])
  rescue ArgumentError, TypeError
    raise "Invalid date #{entry["date"].inspect} for #{entry["location"] || "unknown location"} " \
          "in #{Paths::EVENTS_YAML} — must be YYYY-MM-DD"
  end
end

# @param entry [Hash] events.yml entry
# @return [String]
def page_title(entry)
  return entry["location"] unless entry["skip"]

  entry["reason"] ? "No Meetup This Week (#{entry["reason"]})" : "No Meetup This Week"
end

# @param entry [Hash] events.yml entry
# @param locations [Hash] locations.yml locations, keyed by name
# @return [EventDetails]
def build_event_details(entry, locations)
  location = locations.fetch(entry["location"]) do
    raise "No location metadata found for '#{entry["location"]}' in #{Paths::LOCATIONS_YAML}"
  end

  cancelled = !!entry["skip"]

  found_events = nil
  if !cancelled && location["webcal"]
    found_events = WebcalEventFinderService.new(location["webcal"]).search_events(Date.parse(entry["date"]))
  end

  EventDetails.new(
    date: entry["date"],
    location_name: entry["location"],
    location_website: location["website"],
    notes: entry["notes"],
    highlight: entry["highlight"],
    wifi_notes: location["wifi_notes"],
    found_events: found_events,
    cancelled: cancelled,
    cancellation_reason: entry["reason"]
  )
end

# @param entry [Hash] events.yml entry
# @param content [String] announcement text (page body and `social_post` frontmatter)
# @return [String] path to the written file
def write_event_file(entry, content)
  meeting_time = Time.parse("#{entry["date"]} 08:00:00 -0600")
  frontmatter = {
    "layout" => "event",
    "title" => page_title(entry),
    "author" => "Automation",
    # Real Time object, not a string, so Psych emits an unquoted YAML timestamp
    # that Bridgetown's frontmatter parser reads back as Time (`data.date.strftime`
    # in the layout requires this). `date` is publish time, distinct from meeting_date.
    "date" => Time.now,
    "categories" => "updates",
    "location" => entry["location"],
    "meeting_date" => meeting_time,
    "social_post" => content
  }
  frontmatter["highlight"] = entry["highlight"] if entry["highlight"]

  path = event_file_path(entry["date"], entry["location"])
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, "#{frontmatter.to_yaml}---\n\n#{content}\n")
  path
end

def main
  mode = "pr"
  date_override = nil
  OptionParser.new do |opts|
    opts.on("--mode=MODE") { |m| mode = m }
    opts.on("--date=DATE") { |d| date_override = d }
  end.parse!(ARGV)

  target_date = date_override || Wednesday.next_from(Date.today).to_s

  events = YAML.load_file(Paths::EVENTS_YAML)["events"] || []
  validate_event_dates!(events)

  entry = find_event_for_date(events, target_date)
  unless entry
    puts "No event scheduled for #{target_date} in #{Paths::EVENTS_YAML}. Nothing to do."
    return
  end

  path = event_file_path(entry["date"], entry["location"])
  if File.exist?(path)
    puts "#{path} already exists. Nothing to do."
    return
  end

  locations = YAML.load_file(Paths::LOCATIONS_YAML)["locations"] || {}
  input = build_event_details(entry, locations)
  content = EventContentService.new(input).generate
  written_path = write_event_file(entry, content)

  puts "Generated #{written_path} (mode=#{mode})"
  # Consumed by the calling workflow to PR/commit the file and stamp the meetup date.
  if ENV["GITHUB_OUTPUT"]
    File.write(ENV["GITHUB_OUTPUT"], "event_file=#{written_path}\nevent_date=#{target_date}\n", mode: "a")
  end
end

main if __FILE__ == $PROGRAM_NAME
