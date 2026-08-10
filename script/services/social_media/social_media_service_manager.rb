# frozen_string_literal: true

require_relative "../../lib/app_logger"
require_relative "../../value_objects/post_result"
require_relative "slack_service"
require_relative "mastodon_service"

# A Factory class to build each platform service and post the message
class SocialMediaServiceManager
  PLATFORMS = {
    slack: -> { SlackService.new },
    mastodon: -> { MastodonService.new }
  }.freeze

  def self.post_to_all(message, platforms: PLATFORMS)
    platforms.map do |name, service_proc|
      service_proc.call.post(message)
    rescue => e
      AppLogger.instance.error "#{name} posting failed: #{e.class}: #{e.message}"
      PostResult.failure(name, "#{e.class}: #{e.message}")
    end
  end
end
