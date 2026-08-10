# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../script/services/social_media/slack_service"

class SlackServiceTest < Minitest::Test
  POST_MESSAGE_URL = "https://slack.com/api/chat.postMessage"

  def test_post_success_is_logged_per_channel
    with_env("SLACK_API_TOKEN" => "test-token", "SLACK_CHANNELS" => "general") do
      stub_request(:post, POST_MESSAGE_URL).to_return(status: 200, body: {ok: true}.to_json)

      out = capture_log { SlackService.new.post("Hello world") }

      assert_includes out, "Posted to Slack channel: general"
    end
  end

  def test_post_sends_to_every_configured_channel
    with_env("SLACK_API_TOKEN" => "test-token", "SLACK_CHANNELS" => "general, random") do
      stub_request(:post, POST_MESSAGE_URL).to_return(status: 200, body: {ok: true}.to_json)

      capture_log { SlackService.new.post("Hello world") }

      assert_requested(:post, POST_MESSAGE_URL, times: 2)
    end
  end

  def test_one_channel_failing_does_not_stop_the_others
    with_env("SLACK_API_TOKEN" => "test-token", "SLACK_CHANNELS" => "broken, general") do
      stub_request(:post, POST_MESSAGE_URL)
        .with(body: hash_including("channel" => "broken"))
        .to_return(status: 200, body: {ok: false, error: "channel_not_found"}.to_json)
      stub_request(:post, POST_MESSAGE_URL)
        .with(body: hash_including("channel" => "general"))
        .to_return(status: 200, body: {ok: true}.to_json)

      out = capture_log { SlackService.new.post("Hello world") }

      assert_includes out, "Failed to post to broken"
      assert_includes out, "Posted to Slack channel: general"
    end
  end

  def test_initialize_raises_when_token_missing
    with_env("SLACK_API_TOKEN" => nil) do
      assert_raises(KeyError) { SlackService.new }
    end
  end

  def test_post_raises_when_channels_missing
    with_env("SLACK_API_TOKEN" => "test-token", "SLACK_CHANNELS" => nil) do
      assert_raises(KeyError) { SlackService.new.post("Hello world") }
    end
  end
end
