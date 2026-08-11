# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../script/services/content/event_content_service"

# AI client stub (ClaudeService/ChatCompletionsService) in
# content-service tests: either returns a fixed response or raises, so
# fallback-to-template behavior can be exercised without a real API call.
StubAiClient = Struct.new(:response) do
  def generate_content(_prompt)
    raise response if response.is_a?(Class) && response < Exception

    response
  end
end

class EventContentServiceTest < Minitest::Test
  def build_event(**overrides)
    EventDetails.new(
      date: "2026-08-19",
      location_name: "The Rayback",
      location_website: "https://www.therayback.com/",
      notes: nil,
      highlight: nil,
      wifi_notes: nil,
      found_events: nil,
      **overrides
    )
  end

  def test_falls_back_to_template_when_ai_client_raises
    content = nil
    log = capture_log do
      content = EventContentService.new(build_event, ai_client: StubAiClient.new(ClaudeService::RequestError)).generate
    end

    assert_includes content, "The Rayback"
    refute_includes content, "https://"
    assert_includes log, "falling back to template"
  end

  def test_uses_ai_response_when_it_succeeds
    content = EventContentService.new(build_event, ai_client: StubAiClient.new("  Generated content  ")).generate

    assert_equal "Generated content", content
  end

  def test_falls_back_to_cancellation_template_when_ai_client_raises_for_cancelled_event
    event = build_event(cancelled: true, cancellation_reason: "Thanksgiving")
    content = nil
    log = capture_log do
      content = EventContentService.new(event, ai_client: StubAiClient.new(ClaudeService::RequestError)).generate
    end

    assert_includes content, "Thanksgiving"
    refute_includes content, "https://"
    assert_includes log, "falling back to template"
  end

  def test_generate_does_not_swallow_a_bug_in_prompt_building
    # A malformed date breaks day_name's Date.parse call inside prompt-building,
    # not the AI call itself - this must raise, not silently fall back to the
    # template, so a code/data bug here doesn't ship as if it were a healthy
    # AI-provider outage.
    event = build_event(date: "not-a-real-date")

    assert_raises(Date::Error) do
      EventContentService.new(event, ai_client: StubAiClient.new("unused")).generate
    end
  end
end
