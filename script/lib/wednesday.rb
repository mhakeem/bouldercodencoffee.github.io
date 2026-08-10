# frozen_string_literal: true

require "date"

# Shared Wednesday-math for generate_event.rb and generate_wednesdays.rb.
module Wednesday
  DAY_OF_WEEK = 3

  # @param date [Date]
  # @return [Date] the next Wednesday from date, inclusive
  def self.next_from(date)
    date + ((DAY_OF_WEEK - date.wday) % 7)
  end
end
