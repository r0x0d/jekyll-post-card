# frozen_string_literal: true

require "jekyll"
require "logger"

require_relative "jekyll-post-card/version"
require_relative "jekyll-post-card/fetcher"
require_relative "jekyll-post-card/post_tag"
require_relative "jekyll-post-card/generator"

module Jekyll
  module PostCard
    # Get the gem's root directory (parent of lib/)
    GEM_ROOT = File.expand_path("..", __dir__)
    ASSET_PATH = File.join(GEM_ROOT, "assets")

    class << self
      def logger
        @logger ||= Logger.new($stdout, level: Logger::INFO)
      end

      def logger=(logger)
        @logger = logger
      end

      def asset_path
        ASSET_PATH
      end
    end
  end
end

