# frozen_string_literal: true

require_relative "../ai/ai_service_manager"
require_relative "../../lib/app_logger"
require_relative "content_template_service"
require_relative "event_prompt_builder"

# Generates the single announcement text used as the event page body and
# Mastodon + Slack posts. Tries the AI client (see AiServiceManager) and
# falls back to ContentTemplateService on error.
class EventContentService
  # @param event [EventDetails]
  # @param ai_client [#generate_content] defaults to AiServiceManager.build
  def initialize(event, ai_client: nil)
    @event = event
    @ai_client = ai_client
  end

  # @return [String] the announcement text
  def generate
    text = EventPromptBuilder.new(event).build
    begin
      ai_client.generate_content(text).strip
    rescue => e
      AppLogger.instance.warn \
        "EventContentService: AI generation failed (#{e.class}: #{e.message}), falling back to template"
      ContentTemplateService.new(event).build_content
    end
  end

  private

  attr_reader :event

  def ai_client
    @ai_client ||= AiServiceManager.build
  end
end
