source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

####
# Welcome to your project's Gemfile, used by Rubygems & Bundler.
#
# To install a plugin, run:
#
#   bundle add new-plugin-name -g bridgetown_plugins
#
# This will ensure the plugin is added to the correct Bundler group.
#
# When you run Bridgetown commands, we recommend using a binstub like so:
#
#   bin/bridgetown start (or console, etc.)
#
# This will help ensure the proper Bridgetown version is running.
####

# If you need to upgrade/switch Bridgetown versions, change the line below
# and then run `bundle update bridgetown`
gem "bridgetown", "~> 1.3.4"

# Uncomment to add file-based dynamic routing to your project:
# gem "bridgetown-routes", "~> 1.3.4"

# Puma is the Rack-compatible web server used by Bridgetown
# (you can optionally limit this to the "development" group)
gem "puma", "< 7"

# Uncomment to use the Inspectors API to manipulate the output
# of your HTML or XML resources:
# gem "nokogiri", "~> 1.13"

# Or for faster parsing of HTML-only resources via Inspectors, use Nokolexbor:
# gem "nokolexbor", "~> 0.4"

gem "bridgetown-feed", "~> 3.1"

# Used by script/ automation (event generation + social media posting), not the site itself
gem "icalendar", "~> 2.10"
gem "mastodon-api", "~> 2.0"
gem "slack-ruby-client", "~> 2.4"
gem "tzinfo", "~> 2.0"

group :development do
  gem "solargraph", "~> 0.51.2"
  gem "standard", "~> 1.45"
  gem "erb_lint", "~> 0.9.0"
end

group :test do
  gem "minitest", "~> 5.25"
  gem "minitest-reporters", "~> 1.8"
  gem "webmock", "~> 3.25"
end
