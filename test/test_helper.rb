# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "jekyll-post-card"
require "minitest/autorun"
require "webmock/minitest"

# Silence logger during tests
Jekyll::PostCard.logger = Logger.new(File::NULL)

module TestHelpers
  def stub_external_url(url, body:, status: 200, headers: {})
    stub_request(:get, url)
      .to_return(
        status: status,
        body: body,
        headers: { "Content-Type" => "text/html" }.merge(headers)
      )
  end

  def sample_html(title: "Test Title", description: "Test description", image: nil, site_name: nil)
    og_image = image ? %(<meta property="og:image" content="#{image}">) : ""
    og_site = site_name ? %(<meta property="og:site_name" content="#{site_name}">) : ""

    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>#{title}</title>
        <meta property="og:title" content="#{title}">
        <meta property="og:description" content="#{description}">
        #{og_image}
        #{og_site}
      </head>
      <body>
        <h1>#{title}</h1>
        <p>#{description}</p>
      </body>
      </html>
    HTML
  end
end

