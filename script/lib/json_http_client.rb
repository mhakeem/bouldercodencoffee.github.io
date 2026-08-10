# frozen_string_literal: true

require "net/http"
require "json"

# Shared HTTP mechanics for JSON-over-SSL API clients.
module JsonHttpClient
  # @param url [String] request URL
  # @param headers [Hash] request headers
  # @param payload [Hash] request body, serialized as JSON
  # @return [Hash] parsed JSON response body
  # @raise [self.class::RequestError] if the response is not a success
  def post_json(url, headers:, payload:)
    uri = URI.parse(url)
    request = Net::HTTP::Post.new(uri)
    headers.each { |name, value| request[name] = value }
    request.body = JSON.dump(payload)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
    raise self.class::RequestError, "#{url} returned #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end
end
