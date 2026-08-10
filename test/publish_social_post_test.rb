# frozen_string_literal: true

require_relative "test_helper"
require_relative "../script/publish_social_post"

class PublishSocialPostTest < Minitest::Test
  FIXTURE_WITH_POST = File.join(__dir__, "fixtures", "event_with_social_post.md")
  FIXTURE_WITHOUT_POST = File.join(__dir__, "fixtures", "event_without_social_post.md")

  def test_raises_when_no_path_given
    assert_raises(ArgumentError) { PublishSocialPost.call([]) }
  end

  def test_raises_when_file_has_no_social_post_field
    error = assert_raises(RuntimeError) { PublishSocialPost.call([FIXTURE_WITHOUT_POST]) }
    assert_includes error.message, "has no social_post frontmatter field"
  end

  def test_posts_the_message_and_prints_confirmation
    posted = nil
    all_succeeded = ->(message) {
      posted = message
      [PostResult.success(:slack), PostResult.success(:mastodon)]
    }

    SocialMediaServiceManager.stub(:post_to_all, all_succeeded) do
      out, = capture_io { PublishSocialPost.call([FIXTURE_WITH_POST]) }
      assert_includes out, "Posted: Code && Coffee is tomorrow"
    end

    assert_equal "Code && Coffee is tomorrow (Wednesday) at The Rayback - 8am start!", posted
  end

  def test_exits_nonzero_and_warns_when_a_platform_fails
    some_failed = ->(_message) {
      [PostResult.success(:slack), PostResult.failure(:mastodon, "401 Unauthorized")]
    }

    SocialMediaServiceManager.stub(:post_to_all, some_failed) do
      _, err = capture_io do
        assert_raises(SystemExit) { PublishSocialPost.call([FIXTURE_WITH_POST]) }
      end
      assert_includes err, "mastodon: 401 Unauthorized"
    end
  end
end
