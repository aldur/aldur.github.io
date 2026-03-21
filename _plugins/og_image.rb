# frozen_string_literal: true

require "base64"
require "cgi"
require "tempfile"

module Jekyll
  # Generates per-post OG images (1200x630 webp) and sets the `image` property
  # on all pages and documents. Posts and micros get a unique OG image rendered
  # from an SVG template with their title; other pages get a site-wide default.
  #
  # Images are written to <source>/images/og/ and only regenerated when missing.
  # Use FORCE_OG=1 to regenerate all images.
  #
  # Requires `magick` (ImageMagick 7) on PATH.
  class OgImageGenerator < Generator
    safe true
    priority :low

    DEFAULT_OG_IMAGE = "/assets/images/og-image.webp"
    BG_IMAGE_PATH = "assets/images/og-image.webp"
    OG_DIR = "images/og"

    # SVG text wrapping parameters (font-size 56, ~984px width).
    CHARS_PER_LINE = 32
    MAX_LINES = 4
    TITLE_X = 108
    TITLE_Y_START = 240
    TITLE_LINE_HEIGHT = 68

    def generate(site)
      og_dir = File.join(site.source, OG_DIR)
      FileUtils.mkdir_p(og_dir)

      # FORCE_OG=1 regenerates all images. Disabled during `jekyll serve`
      # to prevent infinite rebuild loops (writing to source triggers watch).
      force = ENV["FORCE_OG"] == "1" && !site.config["serving"]

      # Load background image once for all OG images.
      bg_path = File.join(site.source, BG_IMAGE_PATH)
      @bg_data_uri = if File.file?(bg_path)
                       "data:image/webp;base64,#{Base64.strict_encode64(File.binread(bg_path))}"
                     end

      site.posts.docs.each do |post|
        process_document(post, og_dir, false, force)
      end

      if site.collections.key?("micros")
        site.collections["micros"].docs.each do |micro|
          process_document(micro, og_dir, true, force)
        end
      end

      site.pages.each { |page| set_default(page) }
    end

    private

    def slug_from_url(url)
      # /articles/2025/07/12/lagging-indicators.html -> articles-2025-07-12-lagging-indicators
      # /micros/2025/10/02/unresponsive-claude/      -> micros-2025-10-02-unresponsive-claude
      url.gsub(%r{^/|/+$}, "").gsub(%r{\.html$}, "").tr("/", "-")
    end

    def process_document(doc, og_dir, is_micro, force)
      # Don't override an explicitly set image in front matter.
      return if doc.data.key?("image") && !doc.data["image"].nil?

      slug = slug_from_url(doc.url)

      # Validate slug: only alphanumeric, hyphens, underscores.
      unless slug.match?(/\A[a-zA-Z0-9_-]+\z/)
        Jekyll.logger.warn "OG Image:", "Skipping invalid slug: #{slug.inspect}"
        return
      end

      og_path = File.join(og_dir, "#{slug}.webp")

      unless !force && File.file?(og_path)
        title = doc.data["title"]
        if title.nil? || title.strip.empty?
          doc.data["image"] = DEFAULT_OG_IMAGE
          return
        end

        generate_image(title, slug, is_micro, og_path)
      end

      doc.data["image"] = "/#{OG_DIR}/#{slug}.webp"
    end

    def set_default(page)
      return if page.data.key?("image") && !page.data["image"].nil?

      page.data["image"] = DEFAULT_OG_IMAGE
    end

    def generate_image(title, slug, is_micro, output_path)
      Jekyll.logger.info "OG Image:", "Generating #{slug}"
      tspans = wrap_title(title)
      svg = build_svg(tspans, is_micro)

      Tempfile.create(["og-", ".svg"]) do |tmp|
        tmp.write(svg)
        tmp.flush

        success = system(
          "magick", "-density", "150",
          tmp.path,
          "-resize", "1200x630!",
          "-quality", "90",
          output_path
        )

        unless success
          Jekyll.logger.error "OG Image:", "Failed to generate #{slug}.webp"
        end
      end
    end

    def wrap_title(title)
      safe = CGI.escapeHTML(title)
      words = safe.split
      lines = []
      current = ""

      words.each do |word|
        if current.empty?
          current = word
        elsif current.length + 1 + word.length <= CHARS_PER_LINE
          current = "#{current} #{word}"
        else
          lines << current
          current = word
        end
      end
      lines << current unless current.empty?

      if lines.length > MAX_LINES
        lines = lines[0, MAX_LINES]
        lines[-1] = "#{lines[-1]}..."
      end

      lines.each_with_index.map do |line, i|
        y = TITLE_Y_START + i * TITLE_LINE_HEIGHT
        %(<tspan x="#{TITLE_X}" y="#{y}">#{line}</tspan>)
      end.join("\n    ")
    end

    def build_svg(title_tspans, is_micro)
      bg = if @bg_data_uri
             <<~BG
               <image href="#{@bg_data_uri}" width="1200" height="630"/>
               <rect width="1200" height="630" fill="black" opacity="0.55"/>
             BG
           else
             '<rect width="1200" height="630" fill="#16213e"/>'
           end

      micro_badge = if is_micro
                      '<text x="108" y="562" font-family="sans-serif" font-size="42" font-weight="700" fill="rgba(255,255,255,0.85)">&#x03BC;</text>'
                    else
                      ""
                    end

      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1200" height="630" viewBox="0 0 1200 630">
          #{bg}
          <rect x="80" y="80" width="4" height="470" rx="2" fill="#FFAC33" opacity="0.8"/>
          <svg x="108" y="80" width="52" height="52" viewBox="0 0 36 36">
            <path fill="#269" d="M36 32c0 2.209-1.791 4-4 4H4c-2.209 0-4-1.791-4-4V4c0-2.209 1.791-4 4-4h28c2.209 0 4 1.791 4 4v28z"/>
            <path fill="#F4900C" d="M11 9s7.29-4.557 21-4.969c.652-.02 2-.031 2 .969-6 9-9 23-9 23L11 9z"/>
            <path fill="#FFAC33" d="M12 16S24 5 32 4.031C32.647 3.952 34 4 34 5c-7 4-12 19-12 19l-10-8z"/>
            <path fill="#FFD983" d="M15.156 12.438c.826.727 2.388 1.164 3.471.972l4.892-.866c1.084-.192 1.613.478 1.178 1.488l-1.968 4.563c-.436 1.01-.369 2.63.148 3.602l2.335 4.384c.518.972.044 1.682-1.051 1.58l-4.947-.463c-1.095-.102-2.616.462-3.379 1.254l-3.45 3.577c-.763.792-1.585.562-1.827-.512L9.469 27.17c-.241-1.073-1.248-2.345-2.237-2.827l-4.467-2.175c-.989-.481-1.024-1.335-.078-1.896l4.274-2.534c.946-.561 1.845-1.911 1.997-3.001l.689-4.92c.152-1.09.953-1.387 1.779-.66l3.73 3.281z"/>
          </svg>
          <text x="172" y="118" font-family="sans-serif" font-size="28" font-weight="400" fill="#f0f0f0" letter-spacing="0.5">Universal Bits</text>
          <text font-family="sans-serif" font-size="56" font-weight="700" fill="#f0f0f0">
            #{title_tspans}
          </text>
          #{micro_badge}
          <text x="1092" y="560" font-family="sans-serif" font-size="22" fill="rgba(255,255,255,0.85)" text-anchor="end" letter-spacing="0.3">aldur.blog</text>
        </svg>
      SVG
    end
  end
end
