# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../script/services/ai/chat_completions_service"

class ChatCompletionsServiceTest < Minitest::Test
  BASE_URL = "https://api.groq.com/openai/v1/chat/completions"

  def setup
    ENV["GROQ_API_KEY"] = "test-key"
    @service = ChatCompletionsService.new(base_url: BASE_URL, model: "test-model", api_key_env: "GROQ_API_KEY")
  end

  def test_generate_content_returns_extracted_text_on_success
    stub_request(:post, BASE_URL)
      .to_return(status: 200, body: {choices: [{message: {content: "Hello world"}}]}.to_json)

    assert_equal "Hello world", @service.generate_content("prompt")
  end

  def test_generate_content_raises_request_error_on_non_success_status
    stub_request(:post, BASE_URL).to_return(status: 500, body: "internal error")

    error = assert_raises(ChatCompletionsService::RequestError) { @service.generate_content("prompt") }
    assert_includes error.message, "500"
  end

  def test_generate_content_raises_request_error_on_malformed_body
    stub_request(:post, BASE_URL).to_return(status: 200, body: "{}")

    assert_raises(ChatCompletionsService::RequestError) { @service.generate_content("prompt") }
  end

  def test_initialize_raises_when_api_key_missing
    with_env("GROQ_API_KEY" => nil) do
      assert_raises(ChatCompletionsService::ApiKeyMissingError) do
        ChatCompletionsService.new(base_url: BASE_URL, model: "test-model", api_key_env: "GROQ_API_KEY")
      end
    end
  end

  def test_generate_content_does_not_rescue_network_level_errors
    # Same intent as ClaudeServiceTest's equivalent case - network failures
    # must propagate to EventContentService#generate's rescue, not be
    # swallowed here.
    stub_request(:post, BASE_URL).to_timeout

    assert_raises(Net::OpenTimeout) { @service.generate_content("prompt") }
  end
end
