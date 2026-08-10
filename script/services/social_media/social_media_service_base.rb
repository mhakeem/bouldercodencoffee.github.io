# frozen_string_literal: true

require_relative "../../lib/app_logger"

class SocialMediaServiceBase
  def initialize
    @logger = AppLogger.instance
  end

  def post(message)
    raise NotImplementedError, "#{self.class} must implement #post"
  end

  protected

  attr_reader :logger
end
