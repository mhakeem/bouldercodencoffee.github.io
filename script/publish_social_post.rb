#!/usr/bin/env ruby
# frozen_string_literal: true

# Posts the `social_post` frontmatter field of a src/_events/*.md file to
# Mastodon + Slack. Run only after that event page has actually deployed —
# see .github/workflows/post-to-socials.yml.
#
# Usage: script/publish_social_post.rb path/to/src/_events/2026-08-19-the-rayback.md

require "bundler/setup"
require_relative "lib/frontmatter"
require_relative "services/social_media/social_media_service_manager"

module PublishSocialPost
  # @param argv [Array<String>] ARGV; argv[0] is the event file path
  # @raise [ArgumentError] if no path is given
  # @raise [RuntimeError] if the file has no social_post frontmatter field
  def self.call(argv)
    path = argv[0] || raise(ArgumentError, "Usage: publish_social_post.rb <path to event file>")
    frontmatter, = Frontmatter.read(path)
    message = frontmatter["social_post"] || raise("#{path} has no social_post frontmatter field")

    results = SocialMediaServiceManager.post_to_all(message)
    failures = results.select(&:failure?)

    if failures.empty?
      puts "Posted: #{message}"
    else
      failures.each { |r| warn "#{r.platform}: #{r.error}" }
      exit 1
    end
  end
end

PublishSocialPost.call(ARGV) if __FILE__ == $PROGRAM_NAME
