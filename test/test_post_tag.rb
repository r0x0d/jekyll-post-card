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

  def test_hide_image_option_hides_image_container
    post = mock_post(
      url: "/hidden-image-post",
      title: "Post with Hidden Image",
      date: Time.new(2024, 1, 1),
      image: "/images/featured.jpg"
    )
    @site.posts.docs << post

    tag = create_tag("/hidden-image-post hide_image:true")
    html = tag.render(@context)

    assert_includes html, "no-image"
    refute_includes html, "post-card-image-container"
    refute_includes html, 'src="/images/featured.jpg"'
  end

  def test_hide_image_false_shows_image
    post = mock_post(
      url: "/visible-image-post",
      title: "Post with Visible Image",
      date: Time.new(2024, 1, 1),
      image: "/images/featured.jpg"
    )
    @site.posts.docs << post

    tag = create_tag("/visible-image-post hide_image:false")
    html = tag.render(@context)

    refute_includes html, "no-image"
    assert_includes html, "post-card-image-container"
    assert_includes html, 'src="/images/featured.jpg"'
  end

  def test_hide_image_accepts_yes_value
    post = mock_post(
      url: "/yes-hidden-post",
      title: "Post Hidden with Yes",
      date: Time.new(2024, 1, 1),
      image: "/images/featured.jpg"
    )
    @site.posts.docs << post

    tag = create_tag("/yes-hidden-post hide_image:yes")
    html = tag.render(@context)

    assert_includes html, "no-image"
    refute_includes html, "post-card-image-container"
  end

  def test_link_is_overlay_not_wrapper
    # Verify the link is positioned after content, not wrapping it
    # This prevents lightbox interference with post card clicks
    post = mock_post(
      url: "/overlay-test",
      title: "Overlay Test Post",
      date: Time.new(2024, 1, 1),
      image: "/images/test.jpg"
    )
    @site.posts.docs << post

    tag = create_tag("/overlay-test")
    html = tag.render(@context)

    # Link should come after the arrow div, not before post-card-inner
    assert_match(/post-card-arrow.*post-card-link/m, html)
    # Image container should NOT be inside the link
    refute_match(/<a[^>]*post-card-link[^>]*>.*post-card-image-container/m, html)
  end

  def test_link_does_not_wrap_image_container
    # Ensures image is outside link to prevent lightbox conflicts
    post = mock_post(
      url: "/link-structure-test",
      title: "Link Structure Test",
      date: Time.new(2024, 1, 1),
      image: "/images/photo.jpg"
    )
    @site.posts.docs << post

    tag = create_tag("/link-structure-test")
    html = tag.render(@context)

    # The image container should appear before the link in the HTML
    image_pos = html.index("post-card-image-container")
    link_pos = html.index("post-card-link")

    assert image_pos < link_pos, "Image container should appear before link in HTML"
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

