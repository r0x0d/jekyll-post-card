# frozen_string_literal: true

require_relative "test_helper"

class TestVersion < Minitest::Test
  def test_has_version_number
    refute_nil Jekyll::PostCard::VERSION
  end

  def test_version_format
    assert_match(/\A\d+\.\d+\.\d+\z/, Jekyll::PostCard::VERSION)
  end
end

