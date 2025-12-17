# frozen_string_literal: true

require_relative "test_helper"

class TestPostTag < Minitest::Test
  include TestHelpers

  def setup
    @site = mock_site
    @context = mock_context(@site)
  end

  def test_parses_internal_url
    tag = create_tag("/2024/01/01/my-post")

    refute tag.send(:external_url?)
  end

  def test_parses_external_url
    tag = create_tag("https://example.com/article")

    assert tag.send(:external_url?)
  end

  def test_parses_variant_option
    tag = create_tag("/my-post variant:compact")

    assert_equal "compact", tag.instance_variable_get(:@variant)
  end

  def test_defaults_to_default_variant
    tag = create_tag("/my-post")

    assert_equal "default", tag.instance_variable_get(:@variant)
  end

  def test_ignores_invalid_variant
    tag = create_tag("/my-post variant:invalid")

    assert_equal "default", tag.instance_variable_get(:@variant)
  end

  def test_renders_internal_post_card
    post = mock_post(
      url: "/2024/01/01/test-post",
      title: "Test Post",
      date: Time.new(2024, 1, 1),
      excerpt: "This is a test excerpt"
    )
    @site.posts.docs << post

    tag = create_tag("/2024/01/01/test-post")
    html = tag.render(@context)

    assert_includes html, "post-card"
    assert_includes html, "Test Post"
    assert_includes html, "This is a test excerpt"
    assert_includes html, 'href="/2024/01/01/test-post"'
    assert_includes html, "Internal"
  end

  def test_renders_external_post_card
    url = "https://example.com/article"
    stub_external_url(url, body: sample_html(
      title: "External Article",
      description: "External description",
      site_name: "Example Site"
    ))

    tag = create_tag(url)
    html = tag.render(@context)

    assert_includes html, "post-card"
    assert_includes html, "external"
    assert_includes html, "External Article"
    assert_includes html, "External description"
    assert_includes html, "Example Site"
    assert_includes html, 'target="_blank"'
  end

  def test_renders_error_for_missing_post
    tag = create_tag("/non-existent-post")
    html = tag.render(@context)

    assert_includes html, "error"
    assert_includes html, "Unable to load post"
    assert_includes html, "Post not found"
  end

  def test_renders_compact_variant
    post = mock_post(
      url: "/test-post",
      title: "Compact Post",
      date: Time.new(2024, 1, 1)
    )
    @site.posts.docs << post

    tag = create_tag("/test-post variant:compact")
    html = tag.render(@context)

    assert_includes html, "compact"
  end

  def test_escapes_html_in_content
    post = mock_post(
      url: "/xss-post",
      title: "<script>alert('xss')</script>",
      date: Time.new(2024, 1, 1),
      excerpt: "Test <b>bold</b>"
    )
    @site.posts.docs << post

    tag = create_tag("/xss-post")
    html = tag.render(@context)

    refute_includes html, "<script>"
    assert_includes html, "&lt;script&gt;"
    refute_includes html, "<b>bold</b>"
    assert_includes html, "&lt;b&gt;bold&lt;/b&gt;"
  end

  def test_renders_post_with_image
    post = mock_post(
      url: "/image-post",
      title: "Post with Image",
      date: Time.new(2024, 1, 1),
      image: "/images/featured.jpg"
    )
    @site.posts.docs << post

    tag = create_tag("/image-post")
    html = tag.render(@context)

    assert_includes html, 'src="/images/featured.jpg"'
    assert_includes html, "post-card-image"
    refute_includes html, "no-image"
  end

  def test_renders_post_without_image
    post = mock_post(
      url: "/no-image-post",
      title: "Post without Image",
      date: Time.new(2024, 1, 1)
    )
    @site.posts.docs << post

    tag = create_tag("/no-image-post")
    html = tag.render(@context)

    assert_includes html, "no-image"
    assert_includes html, "post-card-placeholder"
  end

  private

  def create_tag(markup)
    Jekyll::PostCard::PostTag.parse(
      "post",
      markup,
      Liquid::Tokenizer.new(""),
      Liquid::ParseContext.new
    )
  end

  def mock_site
    site = Object.new
    posts = Object.new
    docs = []

    posts.define_singleton_method(:docs) { docs }
    site.define_singleton_method(:posts) { posts }

    site
  end

  def mock_context(site)
    context = Object.new
    registers = { site: site }
    context.define_singleton_method(:registers) { registers }
    context
  end

  def mock_post(url:, title:, date:, excerpt: nil, image: nil)
    post = Object.new
    data = {
      "title" => title,
      "excerpt" => excerpt ? MockExcerpt.new(excerpt) : nil,
      "image" => image
    }

    post.define_singleton_method(:url) { url }
    post.define_singleton_method(:data) { data }
    post.define_singleton_method(:date) { date }
    post.define_singleton_method(:content) { excerpt || "" }

    post
  end

  class MockExcerpt
    def initialize(text)
      @text = text
    end

    def to_s
      @text
    end
  end
end

