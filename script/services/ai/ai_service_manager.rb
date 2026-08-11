# frozen_string_literal: true

require_relative "claude_service"
require_relative "chat_completions_service"

# A Factory module to build the AI service selected by the AI_PROVIDER env var.
module AiServiceManager
  PROVIDERS = {
    "openrouter" => {
      base_url: "https://openrouter.ai/api/v1/chat/completions",
      # NOTE: OpenRouter's free model change often
      default_model: "nvidia/nemotron-3-ultra-550b-a55b:free",
      api_key_env: "OPENROUTER_API_KEY"
    },
    "groq" => {
      base_url: "https://api.groq.com/openai/v1/chat/completions",
      default_model: "openai/gpt-oss-120b",
      api_key_env: "GROQ_API_KEY"
    },
    "mistral" => {
      base_url: "https://api.mistral.ai/v1/chat/completions",
      default_model: "mistral-small-latest",
      api_key_env: "MISTRAL_API_KEY"
    }
  }.freeze

  # Builds the AI service configured via the AI_PROVIDER and AI_MODEL env vars.
  # @return [#generate_content] the configured service (defaults to ClaudeService)
  def self.build
    provider = ENV.fetch("AI_PROVIDER", "claude")
    return ClaudeService.new if provider == "claude"

    config = PROVIDERS.fetch(provider) do
      raise "Unknown AI_PROVIDER: #{provider.inspect} (expected claude, #{PROVIDERS.keys.join(", ")})"
    end

    ChatCompletionsService.new(
      base_url: config[:base_url],
      model: ENV.fetch("AI_MODEL", config[:default_model]),
      api_key_env: config[:api_key_env]
    )
  end
end
