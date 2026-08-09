# frozen_string_literal: true

require "slack-ruby-client"
require_relative "social_media_service_base"
require_relative "../../value_objects/post_result"

class SlackService < SocialMediaServiceBase
  def initialize
    super
    Slack.configure { |config| config.token = ENV.fetch("SLACK_API_TOKEN") }
    @client = Slack::Web::Client.new
  end

  def post(message)
    errors = channels.each_with_object([]) do |channel, errs|
      @client.chat_postMessage(channel: channel, text: message)
      logger.info "Posted to Slack channel: #{channel}"
    rescue => e
      logger.error "Failed to post to #{channel}: #{e.message}"
      errs << "#{channel}: #{e.message}"
    end

    errors.empty? ? PostResult.success(:slack) : PostResult.failure(:slack, errors.join("; "))
  end

  private

  def channels
    ENV.fetch("SLACK_CHANNELS").split(/\s*,\s*/) # comma regex
  end
end
