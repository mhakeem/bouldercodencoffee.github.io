# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../script/services/content/content_template_service"

class ContentTemplateServiceTest < Minitest::Test
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

  def test_build_content_has_no_link_or_hashtags
    content = ContentTemplateService.new(@event).build_content

    refute_includes content, "https://"
    refute_includes content, "#"
  end

  def test_build_content_includes_fixed_announcement_line
    content = ContentTemplateService.new(@event).build_content

    assert_includes content, "Code && Coffee is tomorrow (Wednesday) at The Rayback - 8am start!"
    assert_includes content, "🧑‍💻👩‍💻👨‍💻"
  end

  def test_build_content_includes_highlight_when_present
    event = EventDetails.new(**@event.to_h.merge(highlight: "First meetup of 2026!"))
    content = ContentTemplateService.new(event).build_content

    assert_includes content, "First meetup of 2026!"
  end

  def test_build_content_includes_food_truck_info_when_found
    event = EventDetails.new(**@event.to_h.merge(found_events: [NullWebcalEvent.new, found_lunch]))
    content = ContentTemplateService.new(event).build_content

    assert_includes content, "Temaki Tornado"
    assert_includes content, "Fresh handrolls and sushi"
  end

  def test_build_content_omits_food_truck_mention_when_not_found
    content = ContentTemplateService.new(@event).build_content

    refute_includes content, "food truck"
  end

  def test_build_content_for_cancelled_event_includes_reason
    event = EventDetails.new(**@event.to_h.merge(cancelled: true, cancellation_reason: "Thanksgiving"))
    content = ContentTemplateService.new(event).build_content

    assert_includes content, "No Code && Coffee this week (Thanksgiving)"
    assert_includes content, "🧑‍💻👩‍💻👨‍💻"
    refute_includes content, "https://"
    refute_includes content, "#"
  end

  def test_build_content_for_cancelled_event_without_reason_still_reads_naturally
    event = EventDetails.new(**@event.to_h.merge(cancelled: true))
    content = ContentTemplateService.new(event).build_content

    assert_includes content, "No Code && Coffee this week."
  end
end
