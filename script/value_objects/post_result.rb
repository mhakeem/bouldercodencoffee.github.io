# frozen_string_literal: true

# A simple result Monad of a social platform's #post call
PostResult = Data.define(:platform, :error) do
  def self.success(platform) = new(platform: platform, error: nil)

  def self.failure(platform, error) = new(platform: platform, error: error)

  def success? = error.nil?

  def failure? = !success?
end
