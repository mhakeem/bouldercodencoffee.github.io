# frozen_string_literal: true

require "mastodon"
require_relative "social_media_service_base"
require_relative "../../value_objects/post_result"

class MastodonService < SocialMediaServiceBase
  def initialize
    super
    @client = Mastodon::REST::Client.new(
      base_url: ENV.fetch("MASTODON_BASE_URL"),
      bearer_token: ENV.fetch("MASTODON_API_TOKEN")
    )
  end

  def post(message)
    @client.create_status(message)
    logger.info "Posted to Mastodon: #{message}"
    PostResult.success(:mastodon)
  rescue => e
    logger.error "Error posting to Mastodon: #{e.message}"
    PostResult.failure(:mastodon, e.message)
  end
end
