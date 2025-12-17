# frozen_string_literal: true

module Jekyll
  module PostCard
    # Custom static file that allows specifying the destination directory
    class CssFile < Jekyll::StaticFile
      def initialize(site, base, dir, name, dest_dir)
        super(site, base, dir, name)
        @dest_dir = dest_dir
      end

      def destination_rel_dir
        @dest_dir
      end

      def destination(dest)
        File.join(dest, @dest_dir, @name)
      end
    end

    # Generator that copies the post-card CSS to the site's assets
    class Generator < Jekyll::Generator
      safe true
      priority :lowest

      def generate(site)
        asset_source = Jekyll::PostCard.asset_path
        css_source = File.join(asset_source, "post-card.css")

        unless File.exist?(css_source)
          Jekyll::PostCard.logger.warn("post-card.css not found at #{css_source}")
          return
        end

        # Add CSS file as a static file with custom destination
        site.static_files << CssFile.new(
          site,
          asset_source,
          "",
          "post-card.css",
          "/assets/css"
        )
      end
    end
  end
end

