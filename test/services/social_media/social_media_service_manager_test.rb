# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../script/services/social_media/social_media_service_manager"

class SocialMediaServiceManagerTest < Minitest::Test
  RecordingService = Struct.new(:posts) do
    def post(message)
      posts << message
    end
  end

  def test_one_platform_failing_does_not_block_the_other
    posts = []
    platforms = {
      broken: -> { raise "boom" },
      working: -> { RecordingService.new(posts) }
    }

    log = capture_log { SocialMediaServiceManager.post_to_all("hello", platforms: platforms) }

    assert_equal ["hello"], posts
    assert_includes log, "broken posting failed"
  end

  def test_default_platforms_post_to_the_real_services
    with_env("SLACK_API_TOKEN" => "test-token", "SLACK_CHANNELS" => "general",
      "MASTODON_BASE_URL" => "https://mastodon.example", "MASTODON_API_TOKEN" => "test-token") do
      stub_request(:post, "https://slack.com/api/chat.postMessage").to_return(status: 200, body: {ok: true}.to_json)
      stub_request(:post, "https://mastodon.example/api/v1/statuses").to_return(status: 200, body: {id: "1"}.to_json)

      results = nil
      capture_log { results = SocialMediaServiceManager.post_to_all("hello") }

      assert_equal [true, true], results.map(&:success?)
    end
  end
end
