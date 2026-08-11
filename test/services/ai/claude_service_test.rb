# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../script/services/ai/claude_service"

class ClaudeServiceTest < Minitest::Test
  def test_generate_content_returns_extracted_text_on_success
    with_env("ANTHROPIC_API_KEY" => "test-key") do
      stub_request(:post, ClaudeService::API_URL)
        .to_return(status: 200, body: {content: [{text: "Hello world"}]}.to_json)

      assert_equal "Hello world", ClaudeService.new.generate_content("prompt")
    end
  end

  def test_generate_content_raises_request_error_on_non_success_status
    with_env("ANTHROPIC_API_KEY" => "test-key") do
      stub_request(:post, ClaudeService::API_URL).to_return(status: 500, body: "internal error")

      error = assert_raises(ClaudeService::RequestError) { ClaudeService.new.generate_content("prompt") }
      assert_includes error.message, "500"
    end
  end

  def test_generate_content_raises_request_error_on_malformed_body
    with_env("ANTHROPIC_API_KEY" => "test-key") do
      stub_request(:post, ClaudeService::API_URL).to_return(status: 200, body: "{}")

      assert_raises(ClaudeService::RequestError) { ClaudeService.new.generate_content("prompt") }
    end
  end

  def test_initialize_raises_when_api_key_missing
    with_env("ANTHROPIC_API_KEY" => nil) do
      assert_raises(ClaudeService::ApiKeyMissingError) { ClaudeService.new }
    end
  end

  def test_generate_content_does_not_rescue_network_level_errors
    # Network failures (timeouts, connection resets) are meant to propagate
    # all the way up to EventContentService#generate's rescue, not be caught
    # here as a RequestError - this pins down that ClaudeService itself does
    # no rescuing of its own beyond the explicit RequestError raises.
    with_env("ANTHROPIC_API_KEY" => "test-key") do
      stub_request(:post, ClaudeService::API_URL).to_timeout

      assert_raises(Net::OpenTimeout) { ClaudeService.new.generate_content("prompt") }
    end
  end
end
