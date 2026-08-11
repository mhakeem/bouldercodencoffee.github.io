# frozen_string_literal: true

require "date"
require_relative "../../value_objects/event_details"

# Fills a static template from event/location data only.
# Used when the configured AI provider is unavailable, unset, or errors out.
# See EventContentService.
class ContentTemplateService
  # Rotating variety without needing AI, picked deterministically by date.
  HOOKS = [
    "☕ Time to trade the home office for good coffee and good company.",
    "💻 Another Wednesday, another excuse to code somewhere that isn't your kitchen table.",
    "🧑‍💻 Remote work is great until you miss people. Fix that this week."
  ].freeze

  # Call To Actions
  CTAS = [
    "Remote workers, come hang! Join fellow devs for coffee, coding, and community until whenever.",
    "Escape the home office and find your people! Coffee, code, and community until whenever you're done.",
    "Remote devs, get out and connect! Join us for coffee, coding, and community until whenever you're ready to wrap."
  ].freeze

  # @param event [EventDetails]
  def initialize(event)
    @event = event
  end

  # @return [String] the announcement text
  def build_content
    return cancellation_content if event.cancelled?

    lines = []
    lines << "🎉 #{event.highlight} 🎉" if event.highlight
    lines << rotating(HOOKS)
    lines << ""
    lines << "💻☕️ Code && Coffee is tomorrow (#{day_name}) at #{event.location_name} - 8am start!"
    lines << ""
    lines << rotating(CTAS)
    lines << "" << food_truck_line if food_truck_line
    lines << "" << "See you there! 🧑‍💻👩‍💻👨‍💻"
    lines.join("\n")
  end

  private

  def cancellation_content
    message = "No Code && Coffee this week"
    message += " (#{event.cancellation_reason})" if event.cancellation_reason
    "#{message}. See you next time! 🧑‍💻👩‍💻👨‍💻"
  end

  attr_reader :event

  def rotating(options)
    options[Date.parse(event.date).jd % options.size]
  end

  def day_name
    Date.parse(event.date).strftime("%A")
  end

  def food_truck_line
    return @food_truck_line if defined?(@food_truck_line)

    breakfast, lunch = event.found_events
    truck = lunch&.found? ? lunch : breakfast
    @food_truck_line =
      if truck&.found?
        "This week's food truck: #{truck.summary}\n#{truck.description}"
      end
  end
end
