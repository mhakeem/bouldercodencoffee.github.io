# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../script/services/social_media/mastodon_service"

class MastodonServiceTest < Minitest::Test
  STATUSES_URL = "https://mastodon.example/api/v1/statuses"

  def setup
    with_env("MASTODON_BASE_URL" => "https://mastodon.example", "MASTODON_API_TOKEN" => "test-token") do
      @service = MastodonService.new
    end
  end

  def test_post_success_is_logged
    stub_request(:post, STATUSES_URL).to_return(status: 200, body: {id: "1"}.to_json)

    out = capture_log { @service.post("Hello world") }

    assert_includes out, "Posted to Mastodon: Hello world"
  end

  def test_post_failure_is_rescued_and_logged_not_raised
    stub_request(:post, STATUSES_URL).to_return(status: 500, body: "internal error")

    out = capture_log { @service.post("Hello world") }

    assert_includes out, "Error posting to Mastodon"
  end

  def test_initialize_raises_when_base_url_missing
    with_env("MASTODON_BASE_URL" => nil, "MASTODON_API_TOKEN" => "test-token") do
      assert_raises(KeyError) { MastodonService.new }
    end
  end

  def test_initialize_raises_when_token_missing
    with_env("MASTODON_BASE_URL" => "https://mastodon.example", "MASTODON_API_TOKEN" => nil) do
      assert_raises(KeyError) { MastodonService.new }
    end
  end
end
