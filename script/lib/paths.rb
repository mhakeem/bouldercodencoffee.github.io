# frozen_string_literal: true

# Shared filesystem paths for the automation scripts, so generate_event.rb
# and publish_social_post.rb (both top-level scripts, required into the same
# process by the test suite) don't redefine the same constants.
module Paths
  ROOT = File.expand_path(File.join(__dir__, "..", ".."))
  EVENTS_YAML = File.join(ROOT, "data", "social_automation", "events.yml")
  LOCATIONS_YAML = File.join(ROOT, "data", "social_automation", "locations.yml")
  EVENTS_DIR = File.join(ROOT, "src", "_events")
  DRAFTS_DIR = File.join(ROOT, "_social_drafts")
end
