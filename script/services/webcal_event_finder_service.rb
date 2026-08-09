# frozen_string_literal: true

require "open-uri"
require "net/http"
require "icalendar"
require "date"
require "time"
require "tzinfo"

# To avoid a deprecation warning for tzinfo gem
ActiveSupport.to_time_preserves_timezone = true

# Searches a venue's public webcal feed for food-truck events
# (breakfast/lunch) on a given date. (p.s. built on The Rayback's ical)
class WebcalEventFinderService
  class WebcalFetchingError < StandardError; end

  attr_reader :calendar

  def initialize(url)
    ics_data = download_ics(url.sub("webcal", "http"))
    @calendar = parse_ics(ics_data)
  end

  def search_events(target_date)
    breakfast_times = 8..9 # am
    lunch_time = 12 # pm

    morning = breakfast_times.map { search_event(target_date, _1) }.detect(&:found?) || NullWebcalEvent.new
    noon = search_event(target_date, lunch_time)
    [morning, noon]
  end

  def search_event(target_date, start_hour)
    events_range = events_in_range(target_date, target_date)
    found_event = events_range.find do |lunch_event|
      event_start = to_mtz(lunch_event.dtstart)

      # Match date in Mountain Time
      event_start.to_date == target_date && event_start.hour == start_hour
    end
    found_event ? WebcalEvent.new(found_event) : NullWebcalEvent.new
  end

  private

  def download_ics(url)
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    raise WebcalFetchingError unless response.is_a?(Net::HTTPSuccess)

    response.body
  end

  def parse_ics(ics_data)
    Icalendar::Calendar.parse(ics_data).first
  end

  def to_mtz(datetime)
    TZConverter.to_us_denver(datetime)
  end

  def events_in_range(start_time, end_time)
    @sorted_events ||= sort_events(calendar.events)
    start_idx = find_start_index(start_time)
    return [] unless start_idx

    collect_events_in_range(start_idx, end_time)
  end

  def sort_events(events)
    events.sort_by { |e| e.dtstart.to_time.to_i }
  end

  def find_start_index(start_time)
    @sorted_events.bsearch_index { |e| e.dtstart.to_time >= start_time.to_time }
  end

  def collect_events_in_range(start_idx, end_time)
    day_in_seconds = 86_399
    cutoff = end_time.to_time + day_in_seconds
    @sorted_events[start_idx..].take_while { |event| event.dtstart.to_time <= cutoff }
  end
end

# Time Zone Converter
class TZConverter
  def self.to_us_denver(datetime)
    mountain_tz = TZInfo::Timezone.get("America/Denver")
    mountain_tz.utc_to_local(datetime.to_time.utc)
  end
end

# Webcal Event class
class WebcalEvent
  class MealTimeNotExistError < StandardError; end

  MEAL_TIME = {
    8 => "Breakfast",
    9 => "Breakfast",
    12 => "Lunch"
  }.freeze

  attr_reader :summary, :description

  def initialize(event)
    @summary = event&.summary&.strip
    @start = TZConverter.to_us_denver event&.dtstart
    @end = TZConverter.to_us_denver event&.dtend
    # The venue's calendar feed embeds HTML (e.g. "<em>...</em>") in descriptions;
    # strip it so downstream social/page copy stays plain text.
    @description = event&.description&.split("\n")&.last&.strip&.gsub(%r{</?[^>]+>}, "")
  end

  def meal_time
    MEAL_TIME.fetch(@start.hour)
  rescue KeyError
    raise MealTimeNotExistError
  end

  def start
    @start.strftime("%I:%M %p")
  end

  def end
    @end.strftime("%I:%M %p")
  end

  def found?
    true
  end
end

class NullWebcalEvent
  attr_reader :summary, :start, :end, :description, :meal_time

  def found?
    false
  end
end
