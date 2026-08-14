# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../script/services/content/event_prompt_builder"
require_relative "../../../script/value_objects/event_details"

class EventPromptBuilderTest < Minitest::Test
  def setup
    @event = EventDetails.new(
      date: "2026-08-19",
      location_name: "The Rayback",
      location_website: "https://www.therayback.com/",
      notes: nil,
      highlight: nil,
      wifi_notes: nil,
      found_events: nil
    )
  end

  def found_lunch
    lunch = WebcalEvent.allocate
    lunch.instance_variable_set(:@summary, "Temaki Tornado")
    lunch.instance_variable_set(:@start, Time.new(2026, 8, 19, 12, 0))
    lunch.instance_variable_set(:@end, Time.new(2026, 8, 19, 13, 0))
    lunch.instance_variable_set(:@description, "Fresh handrolls and sushi")
    lunch
  end

  private :found_lunch

  def test_prompt_omits_food_truck_details_line_when_none_found
    # REAL_EXAMPLES always contain a food-truck line as a style reference —
    # check the actual "Event details" injection specifically, not the whole prompt.
    prompt = EventPromptBuilder.new(@event).build

    refute_includes prompt, "- This week's food truck is called"
  end

  def test_prompt_includes_food_truck_details_line_when_found
    event = EventDetails.new(**@event.to_h.merge(found_events: [NullWebcalEvent.new, found_lunch]))
    prompt = EventPromptBuilder.new(event).build

    assert_includes prompt, "- This week's food truck is called \"Temaki Tornado\""
  end

  def test_prompt_forbids_em_dashes_and_forced_hook_lines
    prompt = EventPromptBuilder.new(@event).build

    assert_includes prompt, "Never use an em dash"
    assert_includes prompt, "don't do this by default"
  end

  def test_prompt_for_cancelled_event_asks_for_a_cancellation_announcement
    event = EventDetails.new(**@event.to_h.merge(cancelled: true, cancellation_reason: "Thanksgiving"))
    prompt = EventPromptBuilder.new(event).build

    assert_includes prompt, "NO"
    assert_includes prompt, "Thanksgiving"
    assert_includes prompt, "em dash"
  end
end
