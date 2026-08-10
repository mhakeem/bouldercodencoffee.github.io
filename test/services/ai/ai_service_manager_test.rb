# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../script/services/ai/ai_service_manager"

class AiServiceManagerTest < Minitest::Test
  def test_defaults_to_claude_when_ai_provider_is_unset
    with_env("AI_PROVIDER" => nil, "ANTHROPIC_API_KEY" => "test-key") do
      assert_instance_of ClaudeService, AiServiceManager.build
    end
  end

  def test_builds_a_chat_completions_service_for_a_known_provider
    with_env("AI_PROVIDER" => "groq", "GROQ_API_KEY" => "test-key") do
      assert_instance_of ChatCompletionsService, AiServiceManager.build
    end
  end

  def test_ai_model_overrides_the_provider_default
    with_env("AI_PROVIDER" => "mistral", "MISTRAL_API_KEY" => "test-key", "AI_MODEL" => "custom-model") do
      client = AiServiceManager.build

      assert_equal "custom-model", client.instance_variable_get(:@model)
    end
  end

  def test_raises_for_an_unknown_provider
    with_env("AI_PROVIDER" => "does-not-exist") do
      assert_raises(RuntimeError) { AiServiceManager.build }
    end
  end
end
