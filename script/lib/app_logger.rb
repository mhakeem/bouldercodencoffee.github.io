# frozen_string_literal: true

require "logger"

# A singleton logger class
class AppLogger
  @instance = Logger.new($stdout)

  class << self
    attr_reader :instance
  end

  private_class_method :new
end
