# frozen_string_literal: true

require_relative "test_helper"

class TestFetcher < Minitest::Test
  include TestHelpers

  def test_fetch_basic_metadata
    url = "https://example.com/article"
    stub_external_url(url, body: sample_html(
      title: "My Article",
      description: "This is a great article",
      image: "https://example.com/image.jpg",
      site_name: "Example Blog"
    ))

    metadata = Jekyll::PostCard::Fetcher.fetch(url)

    assert_equal "My Article", metadata.title
    assert_equal "This is a great article", metadata.description
    assert_equal "https://example.com/image.jpg", metadata.image
    assert_equal "Example Blog", metadata.site_name
    assert_equal url, metadata.url
  end

  def test_fetch_without_image
    url = "https://example.com/no-image"
    stub_external_url(url, body: sample_html(
      title: "No Image Article",
      description: "Article without image"
    ))

    metadata = Jekyll::PostCard::Fetcher.fetch(url)

    assert_equal "No Image Article", metadata.title
    assert_nil metadata.image
  end

  def test_fetch_with_relative_image
    url = "https://example.com/relative-image"
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Relative Image</title>
        <meta property="og:title" content="Relative Image">
        <meta property="og:image" content="/images/test.jpg">
      </head>
      <body></body>
      </html>
    HTML

    stub_external_url(url, body: html)

    metadata = Jekyll::PostCard::Fetcher.fetch(url)

    assert_equal "https://example.com/images/test.jpg", metadata.image
  end

  def test_fetch_falls_back_to_html_title
    url = "https://example.com/no-og"
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>HTML Title Only</title>
        <meta name="description" content="Meta description">
      </head>
      <body></body>
      </html>
    HTML

    stub_external_url(url, body: html)

    metadata = Jekyll::PostCard::Fetcher.fetch(url)

    assert_equal "HTML Title Only", metadata.title
    assert_equal "Meta description", metadata.description
  end

  def test_fetch_handles_http_error
    url = "https://example.com/not-found"
    stub_external_url(url, body: "Not Found", status: 404)

    metadata = Jekyll::PostCard::Fetcher.fetch(url)

    assert_equal "Unable to load post", metadata.title
    assert_equal "error", metadata.type
  end

  def test_fetch_handles_redirect
    original_url = "https://example.com/old-path"
    redirect_url = "https://example.com/new-path"

    stub_request(:get, original_url)
      .to_return(status: 301, headers: { "Location" => redirect_url })

    stub_external_url(redirect_url, body: sample_html(
      title: "Redirected Article"
    ))

    metadata = Jekyll::PostCard::Fetcher.fetch(original_url)

    assert_equal "Redirected Article", metadata.title
  end

  def test_fetch_rejects_invalid_scheme
    metadata = Jekyll::PostCard::Fetcher.fetch("ftp://example.com/file")

    assert_equal "Unable to load post", metadata.title
    assert_equal "error", metadata.type
  end

  def test_fetch_extracts_site_name_from_host
    url = "https://www.example.com/article"
    stub_external_url(url, body: sample_html(title: "Test"))

    metadata = Jekyll::PostCard::Fetcher.fetch(url)

    assert_equal "example.com", metadata.site_name
  end

  def test_fetch_extracts_twitter_card_metadata
    url = "https://example.com/twitter-card"
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Fallback Title</title>
        <meta name="twitter:title" content="Twitter Title">
        <meta name="twitter:description" content="Twitter description">
        <meta name="twitter:image" content="https://example.com/twitter-image.jpg">
      </head>
      <body></body>
      </html>
    HTML

    stub_external_url(url, body: html)

    metadata = Jekyll::PostCard::Fetcher.fetch(url)

    assert_equal "Twitter Title", metadata.title
    assert_equal "Twitter description", metadata.description
    assert_equal "https://example.com/twitter-image.jpg", metadata.image
  end

  def test_fetch_extracts_article_date
    url = "https://example.com/dated-article"
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Dated Article</title>
        <meta property="og:title" content="Dated Article">
        <meta property="article:published_time" content="2024-12-15T10:00:00Z">
      </head>
      <body></body>
      </html>
    HTML

    stub_external_url(url, body: html)

    metadata = Jekyll::PostCard::Fetcher.fetch(url)

    assert_equal Date.new(2024, 12, 15), metadata.date
  end

  def test_fetch_extracts_author
    url = "https://example.com/authored-article"
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Authored Article</title>
        <meta property="og:title" content="Authored Article">
        <meta name="author" content="John Doe">
      </head>
      <body></body>
      </html>
    HTML

    stub_external_url(url, body: html)

    metadata = Jekyll::PostCard::Fetcher.fetch(url)

    assert_equal "John Doe", metadata.author
  end
end

