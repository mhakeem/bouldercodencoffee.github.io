#!/usr/bin/env ruby
# frozen_string_literal: true

# Appends missing Wednesday entries to data/social_automation/events.yml so
# the calendar can be filled out further ahead without hand-typing each
# `- date: / location:` pair. Only appends after the last dated entry —
# never rewrites or reorders existing entries.
#
# Usage:
#   script/generate_wednesdays.rb --through=2026-12-31
#   script/generate_wednesdays.rb --weeks=52
#   script/generate_wednesdays.rb --weeks=52 --location="The Rayback"

require "bundler/setup"
require "yaml"
require "date"
require "optparse"

require_relative "lib/paths"
require_relative "lib/wednesday"

# @param events [Array<Hash>]
# @return [Date, nil]
def last_event_date(events)
  return nil if events.empty?

  events.map { |e| Date.iso8601(e["date"]) }.max
end

# @param events [Array<Hash>]
# @param today [Date]
# @return [Date] the Wednesday after the last existing entry, or the next
#   Wednesday from today (inclusive) if events is empty
def start_date(events, today: Date.today)
  last = last_event_date(events)
  return Wednesday.next_from(today) unless last

  Wednesday.next_from(last + 1)
end

# @param start [Date]
# @param through [Date, nil]
# @param weeks [Integer, nil]
# @return [Array<Date>] weekly dates from start; exactly one of through/weeks must be set
def generate_dates(start, through: nil, weeks: nil)
  if through
    dates = []
    date = start
    while date <= through
      dates << date
      date += 7
    end
    dates
  else
    Array.new(weeks) { |i| start + (i * 7) }
  end
end

# @param locations [Hash] locations.yml locations, keyed by name
# @return [String]
# @raise [RuntimeError] if there isn't exactly one location
def default_location(locations)
  case locations.size
  when 1
    locations.keys.first
  when 0
    raise "No locations found in #{Paths::LOCATIONS_YAML}. Pass --location explicitly."
  else
    raise "Multiple locations found in #{Paths::LOCATIONS_YAML} (#{locations.keys.join(", ")}). " \
          "Pass --location explicitly."
  end
end

# @param dates [Array<Date>]
# @param location [String]
# @param path [String]
# @return [void]
def append_entries(dates, location, path: Paths::EVENTS_YAML)
  content = File.exist?(path) && !File.read(path).strip.empty? ? File.read(path) : "---\nevents:\n"

  new_lines = dates.map do |date|
    "  - date: \"#{date.iso8601}\"\n    location: \"#{location}\"\n"
  end.join

  File.write(path, content.chomp("\n") + "\n" + new_lines)
end

def main
  through = nil
  weeks = nil
  location_override = nil
  OptionParser.new do |opts|
    opts.on("--through=DATE") { |d| through = Date.iso8601(d) }
    opts.on("--weeks=N") { |n| weeks = Integer(n) }
    opts.on("--location=NAME") { |l| location_override = l }
  end.parse!(ARGV)

  if through.nil? == weeks.nil?
    raise "Pass exactly one of --through=YYYY-MM-DD or --weeks=N"
  end

  events = File.exist?(Paths::EVENTS_YAML) ? (YAML.load_file(Paths::EVENTS_YAML)&.[]("events") || []) : []
  locations = File.exist?(Paths::LOCATIONS_YAML) ? (YAML.load_file(Paths::LOCATIONS_YAML)&.[]("locations") || {}) : {}
  location = location_override || default_location(locations)

  dates = generate_dates(start_date(events), through: through, weeks: weeks)
  if dates.empty?
    puts "Nothing to generate."
    return
  end

  append_entries(dates, location)
  puts "Appended #{dates.size} entr#{(dates.size == 1) ? "y" : "ies"} to #{Paths::EVENTS_YAML} " \
       "(#{dates.first.iso8601} through #{dates.last.iso8601})"
end

main if __FILE__ == $PROGRAM_NAME
