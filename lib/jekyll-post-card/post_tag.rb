# frozen_string_literal: true

module Jekyll
  module PostCard
    # Liquid tag for rendering post cards
    # Usage:
    #   {% post_card /2024/01/01/my-post %}
    #   {% post_card https://example.com/article %}
    #   {% post_card /my-post variant:compact %}
    class PostTag < Liquid::Tag
      VALID_VARIANTS = %w[default compact vertical].freeze
      EXTERNAL_URL_PATTERN = %r{^https?://}i

      def initialize(tag_name, markup, tokens)
        super
        parse_arguments(markup.strip)
      end

      def render(context)
        site = context.registers[:site]

        begin
          if external_url?
            render_external_card(context)
          else
            render_internal_card(site, context)
          end
        rescue StandardError => e
          render_error_card("Error rendering card: #{e.message}")
        end
      end

      private

      def parse_arguments(markup)
        parts = markup.split(/\s+/)
        @url = parts.shift || ""
        @options = {}

        parts.each do |part|
          if part.include?(":")
            key, value = part.split(":", 2)
            @options[key.to_sym] = value
          end
        end

        @variant = @options[:variant] || "default"
        @variant = "default" unless VALID_VARIANTS.include?(@variant)
        
        # Parse hide_image option (accepts true, false, yes, no, 1, 0)
        hide_image_value = @options[:hide_image]&.downcase
        @hide_image = %w[true yes 1].include?(hide_image_value)
      end

      def external_url?
        @url.match?(EXTERNAL_URL_PATTERN)
      end

      def render_internal_card(site, _context)
        post = find_post(site)

        if post
          render_card(
            title: post.data["title"] || "Untitled",
            description: extract_excerpt(post),
            image: post.data["image"] || post.data["thumbnail"] || post.data["og_image"],
            url: post.url,
            date: post.date,
            source_type: "internal",
            source_name: "Internal"
          )
        else
          render_error_card("Post not found: #{@url}")
        end
      end

      def extract_excerpt(post)
        # Handle Jekyll's Excerpt object or string excerpt
        excerpt = post.data["excerpt"] || post.data["description"]
        
        if excerpt
          # Clean up whitespace but preserve HTML for proper escaping
          text = excerpt.to_s.gsub(/\s+/, " ").strip
          return text unless text.empty?
        end

        excerpt_from_content(post)
      end

      def render_external_card(_context)
        metadata = Fetcher.fetch(@url)

        if metadata.type == "error"
          render_error_card(metadata.description)
        else
          render_card(
            title: metadata.title,
            description: metadata.description,
            image: metadata.image,
            url: metadata.url,
            date: metadata.date,
            source_type: "external",
            source_name: metadata.site_name
          )
        end
      end

      def find_post(site)
        # Try to find by URL/permalink
        site.posts.docs.find do |post|
          post.url == @url || post.url == "/#{@url}" || post.url == @url.chomp("/")
        end
      end

      def excerpt_from_content(post)
        # Get first 160 characters of content, stripping HTML
        content = post.content.to_s.gsub(/<[^>]*>/, " ").gsub(/\s+/, " ").strip
        content.length > 160 ? "#{content[0, 157]}..." : content
      end

      def render_card(title:, description:, image:, url:, date:, source_type:, source_name:)
        variant_class = @variant == "default" ? "" : " #{@variant}"
        external_class = source_type == "external" ? " external" : ""
        # Hide image if explicitly requested or if no image available
        show_image = image && !@hide_image
        image_class = show_image ? "" : " no-image"

        formatted_date = format_date(date)
        escaped_title = escape_html(title)
        escaped_description = escape_html(description)
        escaped_source = escape_html(source_name)
        escaped_url = escape_html(url)

        target = source_type == "external" ? "_blank" : "_self"
        rel_attr = source_type == "external" ? ' rel="noopener noreferrer"' : ""

        # Use div wrapper like jekyll-github-card to prevent Markdown interference
        # Render image if available, placeholder if no image (unless explicitly hidden)
        image_html = if @hide_image
                       ""
                     else
                       render_image(image, escaped_title)
                     end

        <<~HTML
          <div class="post-card#{variant_class}#{external_class}#{image_class}" data-url="#{escaped_url}">
            <div class="post-card-inner">
              #{image_html}
              <div class="post-card-content">
                <div class="post-card-meta">
                  <span class="post-card-source">
                    #{source_icon(source_type)}
                    #{escaped_source}
                  </span>
                  #{formatted_date ? "<span class=\"post-card-date\">#{formatted_date}</span>" : ""}
                </div>
                <h3 class="post-card-title">#{escaped_title}</h3>
                <p class="post-card-excerpt">#{escaped_description}</p>
              </div>
              <div class="post-card-arrow">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
              </div>
              <a href="#{url}" class="post-card-link" target="#{target}"#{rel_attr}></a>
            </div>
          </div>
        HTML
      end

      def render_image(image, alt)
        if image
          <<~HTML
            <div class="post-card-image-container">
              <img src="#{image}" alt="#{alt}" class="post-card-image" loading="lazy">
            </div>
          HTML
        else
          <<~HTML
            <div class="post-card-image-container">
              <div class="post-card-placeholder">
                <svg viewBox="0 0 24 24" fill="currentColor"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-1 16H6c-.55 0-1-.45-1-1V6c0-.55.45-1 1-1h12c.55 0 1 .45 1 1v12c0 .55-.45 1-1 1zm-4.44-6.19l-2.35 3.02-1.56-1.88c-.2-.25-.58-.24-.78.01l-1.74 2.23c-.26.33-.02.81.39.81h8.98c.41 0 .65-.47.4-.8l-2.55-3.39c-.19-.26-.59-.26-.79 0z"/></svg>
              </div>
            </div>
          HTML
        end
      end

      def render_error_card(message)
        <<~HTML
          <div class="post-card error no-image">
            <div class="post-card-inner">
              <div class="post-card-image-container">
                <div class="post-card-placeholder">
                  <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>
                </div>
              </div>
              <div class="post-card-content">
                <div class="post-card-meta">
                  <span class="post-card-source" style="background: rgba(255, 100, 100, 0.15); color: #ff6b6b;">
                    <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z"/></svg>
                    Error
                  </span>
                </div>
                <h3 class="post-card-title">Unable to load post</h3>
                <p class="post-card-excerpt">#{escape_html(message)}</p>
              </div>
            </div>
          </div>
        HTML
      end

      def source_icon(type)
        if type == "internal"
          '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z"/></svg>'
        else
          '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/></svg>'
        end
      end

      def format_date(date)
        return nil unless date

        if date.respond_to?(:strftime)
          date.strftime("%B %d, %Y")
        else
          date.to_s
        end
      end

      def escape_html(text)
        return "" unless text

        text.to_s
            .gsub("&", "&amp;")
            .gsub("<", "&lt;")
            .gsub(">", "&gt;")
            .gsub('"', "&quot;")
            .gsub("'", "&#39;")
      end
    end
  end
end

# Register the tag - using "post_card" to avoid conflicts with Jekyll internals
Liquid::Template.register_tag("post_card", Jekyll::PostCard::PostTag)

