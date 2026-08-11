# frozen_string_literal: true

require_relative "ai_service_base"

# Thin wrapper around the Claude Messages API using plain Net::HTTP (no SDK dependency).
class ClaudeService < AiServiceBase
  API_URL = "https://api.anthropic.com/v1/messages"
  ANTHROPIC_VERSION = "2023-06-01"
  DEFAULT_MODEL = "claude-haiku-4-5"

  # @param model [String]
  # @raise [ApiKeyMissingError] if ANTHROPIC_API_KEY is not set
  def initialize(model: DEFAULT_MODEL)
    super("ANTHROPIC_API_KEY")
    @model = model
  end

  # @param prompt [String]
  # @param max_tokens [Integer]
  # @return [String] generated content
  # @raise [RequestError] on unexpected response shape
  def generate_content(prompt, max_tokens: 1024)
    headers = {"content-type" => "application/json", "x-api-key" => api_key, "anthropic-version" => ANTHROPIC_VERSION}
    payload = {model: @model, max_tokens:, messages: [{role: "user", content: prompt}]}

    body = post_json(API_URL, headers:, payload:)
    body.dig("content", 0, "text") || raise(RequestError, "Unexpected Claude API response: #{body}")
  end
end
