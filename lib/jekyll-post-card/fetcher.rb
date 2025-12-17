                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            # frozen_string_literal: true

require "net/http"
require "uri"
require "nokogiri"
require "json"

module Jekyll
  module PostCard
    # Fetches metadata from external URLs using Open Graph, Twitter Cards, and HTML meta tags
    class Fetcher
      TIMEOUT = 10
      USER_AGENT = "Jekyll-Post-Card/#{VERSION} (+https://github.com/r0x0d/jekyll-post-card)"

      class FetchError < StandardError; end

      # Metadata structure for a fetched post
      PostMetadata = Struct.new(
        :title,
        :description,
        :image,
        :url,
        :site_name,
        :date,
        :author,
        :type,
        keyword_init: true
      )

      class << self
        def fetch(url)
          uri = validate_url(url)
          html = fetch_html(uri)
          parse_metadata(html, uri)
        rescue FetchError => e
          PostCard.logger.warn("Failed to fetch metadata for #{url}: #{e.message}")
          error_metadata(url, e.message)
        rescue StandardError => e
          PostCard.logger.error("Unexpected error fetching #{url}: #{e.message}")
          error_metadata(url, "Unexpected error occurred")
        end

        private

        def validate_url(url)
          uri = URI.parse(url)
          raise FetchError, "Invalid URL scheme" unless %w[http https].include?(uri.scheme)
          raise FetchError, "Missing host" unless uri.host

          uri
        rescue URI::InvalidURIError => e
          raise FetchError, "Invalid URL: #{e.message}"
        end

        def fetch_html(uri)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == "https"
          http.open_timeout = TIMEOUT
          http.read_timeout = TIMEOUT

          request = Net::HTTP::Get.new(uri)
          request["User-Agent"] = USER_AGENT
          request["Accept"] = "text/html,application/xhtml+xml"

          response = http.request(request)

          case response
          when Net::HTTPSuccess
            response.body
          when Net::HTTPRedirection
            redirect_url = response["location"]
            redirect_uri = URI.parse(redirect_url)
            redirect_uri = URI.join(uri, redirect_url) unless redirect_uri.absolute?
            fetch_html(redirect_uri)
          else
            raise FetchError, "HTTP #{response.code}: #{response.message}"
          end
        end

        def parse_metadata(html, uri)
          doc = Nokogiri::HTML(html)

          PostMetadata.new(
            title: extract_title(doc),
            description: extract_description(doc),
            image: extract_image(doc, uri),
            url: uri.to_s,
            site_name: extract_site_name(doc, uri),
            date: extract_date(doc),
            author: extract_author(doc),
            type: extract_type(doc)
          )
        end

        def extract_title(doc)
          # Priority: og:title > twitter:title > <title>
          og_title = doc.at_css('meta[property="og:title"]')&.[]("content")
          twitter_title = doc.at_css('meta[name="twitter:title"]')&.[]("content")
          html_title = doc.at_css("title")&.text

          (og_title || twitter_title || html_title || "Untitled").strip
        end

        def extract_description(doc)
          # Priority: og:description > twitter:description > meta description
          og_desc = doc.at_css('meta[property="og:description"]')&.[]("content")
          twitter_desc = doc.at_css('meta[name="twitter:description"]')&.[]("content")
          meta_desc = doc.at_css('meta[name="description"]')&.[]("content")

          (og_desc || twitter_desc || meta_desc || "").strip
        end

        def extract_image(doc, base_uri)
          # Priority: og:image > twitter:image
          og_image = doc.at_css('meta[property="og:image"]')&.[]("content")
          twitter_image = doc.at_css('meta[name="twitter:image"]')&.[]("content")

          image_url = og_image || twitter_image
          return nil unless image_url

          # Make relative URLs absolute
          begin
            image_uri = URI.parse(image_url)
            image_uri.absolute? ? image_url : URI.join(base_uri, image_url).to_s
          rescue URI::InvalidURIError
            image_url
          end
        end

        def extract_site_name(doc, uri)
          og_site = doc.at_css('meta[property="og:site_name"]')&.[]("content")
          og_site || uri.host.sub(/^www\./, "")
        end

        def extract_date(doc)
          # Try various date meta tags
          date_selectors = [
            'meta[property="article:published_time"]',
            'meta[name="date"]',
            'meta[name="DC.date"]',
            'meta[name="publish-date"]',
            'time[datetime]'
          ]

          date_selectors.each do |selector|
            element = doc.at_css(selector)
            next unless element

            date_str = element["content"] || element["datetime"]
            next unless date_str

            begin
              return Date.parse(date_str)
            rescue Date::Error
              next
            end
          end

          nil
        end

        def extract_author(doc)
          # Try various author meta tags
          author_selectors = [
            'meta[property="article:author"]',
            'meta[name="author"]',
            'meta[name="DC.creator"]',
            'meta[name="twitter:creator"]'
          ]

          author_selectors.each do |selector|
            element = doc.at_css(selector)
            author = element&.[]("content")
            return author.strip if author && !author.empty?
          end

          nil
        end

        def extract_type(doc)
          og_type = doc.at_css('meta[property="og:type"]')&.[]("content")
          og_type || "article"
        end

        def error_metadata(url, message)
          PostMetadata.new(
            title: "Unable to load post",
            description: "Could not fetch metadata: #{message}",
            image: nil,
            url: url,
            site_name: nil,
            date: nil,
            author: nil,
            type: "error"
          )
        end
      end
    end
  end
end

