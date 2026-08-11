# frozen_string_literal: true

require "bundler/setup"
require "minitest/autorun"
require "minitest/reporters"
require "webmock/minitest"

Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new(color: true)]

module EnvHelper
  # Temporarily sets env vars for the duration of the block, restoring
  # (including unsetting) whatever was there before, even if the block raises.
  def with_env(vars)
    original = vars.keys.to_h { |k| [k, ENV[k]] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    original.each { |k, v| ENV[k] = v }
  end
end

Minitest::Test.include(EnvHelper)

module LogHelper
  # This helper captures AppLogger's output directly since Minitest's
  # capture_io can't intercept it - AppLogger holds its own $stdout
  # reference, not the global.
  def capture_log
    out = StringIO.new
    AppLogger.instance.reopen(out)
    yield
    out.string
  ensure
    AppLogger.instance.reopen($stdout)
  end
end

Minitest::Test.include(LogHelper)
