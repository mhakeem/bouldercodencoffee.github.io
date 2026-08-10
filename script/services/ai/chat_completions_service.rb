# frozen_string_literal: true

require_relative "ai_service_base"

# Generic client for the OpenAI-compatible "/chat/completions" shape shared
# by OpenRouter, Groq, Mistral, etc. See ai_service_manager.rb for provider selection.
class ChatCompletionsService < AiServiceBase
  # @param base_url [String]
  # @param model [String]
  # @param api_key_env [String] env var name holding the API key
  # @raise [ApiKeyMissingError] if api_key_env is not set
  def initialize(base_url:, model:, api_key_env:)
    super(api_key_env)
    @base_url = base_url
    @model = model
  end

  # @param prompt [String]
  # @param max_tokens [Integer]
  # @return [String] generated content
  # @raise [RequestError] on unexpected response shape
  def generate_content(prompt, max_tokens: 1024)
    headers = {"content-type" => "application/json", "authorization" => "Bearer #{api_key}"}
    payload = {model: @model, max_tokens:, messages: [{role: "user", content: prompt}]}

    body = post_json(@base_url, headers:, payload:)
    body.dig("choices", 0, "message", "content") || raise(RequestError, "Unexpected response: #{body}")
  end
end
