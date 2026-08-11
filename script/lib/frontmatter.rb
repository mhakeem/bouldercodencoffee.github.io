# frozen_string_literal: true

require "yaml"
require "date"

# Minimal frontmatter reader for src/_events/*.md files, without pulling in
# the whole Bridgetown site-building machinery.
module Frontmatter
  FRONTMATTER_PATTERN = /\A---\s*\n(.*?\n)---\s*\n(.*)\z/m

  # @param path [String]
  # @return [Array(Hash, String)] parsed frontmatter and the remaining body
  # @raise [RuntimeError] if the file has no frontmatter block
  def self.read(path)
    match = FRONTMATTER_PATTERN.match(File.read(path))
    raise "No frontmatter found in #{path}" unless match

    [YAML.safe_load(match[1], permitted_classes: [Date, Time]), match[2]]
  end
end
