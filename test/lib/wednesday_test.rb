# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../script/lib/wednesday"

class WednesdayTest < Minitest::Test
  def test_next_from_a_tuesday_is_tomorrow
    assert_equal Date.new(2026, 8, 19), Wednesday.next_from(Date.new(2026, 8, 18))
  end

  def test_next_from_a_wednesday_is_the_same_day
    assert_equal Date.new(2026, 8, 19), Wednesday.next_from(Date.new(2026, 8, 19))
  end

  def test_next_from_a_thursday_is_next_week
    assert_equal Date.new(2026, 8, 26), Wednesday.next_from(Date.new(2026, 8, 20))
  end

  def test_next_from_crosses_a_month_boundary
    assert_equal Date.new(2026, 9, 2), Wednesday.next_from(Date.new(2026, 8, 31))
  end

  def test_next_from_crosses_a_year_boundary
    assert_equal Date.new(2027, 1, 6), Wednesday.next_from(Date.new(2026, 12, 31))
  end
end
