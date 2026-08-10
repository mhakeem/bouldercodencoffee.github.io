# frozen_string_literal: true

require_relative "../../lib/json_http_client"

class AiServiceBase
  include JsonHttpClient

  class ApiKeyMissingError < StandardError; end

  class RequestError < StandardError; end

  # @param api_key_env [String] env var name holding the API key
  # @raise [ApiKeyMissingError] if api_key_env is not set
  def initialize(api_key_env)
    @api_key = ENV.fetch(api_key_env) { raise ApiKeyMissingError, "#{api_key_env} is not set" }
  end

  # @param prompt [String]
  # @return [String] generated content
  def generate_content(prompt, max_tokens: 1024)
    raise NotImplementedError, "#{self.class} must implement #generate_content"
  end

  protected

  attr_reader :api_key
end
