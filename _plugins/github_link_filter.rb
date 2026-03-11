# frozen_string_literal: true

module Jekyll
  # Post-render hook that automatically adds a GitHub SVG icon to links
  # pointing to https://github.com/aldur.
  GITHUB_LINK_RE = %r{<a\s([^>]*href="https://github\.com/aldur[^"]*"[^>]*)>((?:(?!</a>).)*)</a>}m

  Jekyll::Hooks.register [:posts, :micros, :pages], :post_render do |doc|
    next unless doc.output
    next unless doc.output.include?("https://github.com/aldur")

    svg_path = File.join(doc.site.source, "_includes", "social-icons", "github.svg.path")
    svg_path_content = File.read(svg_path, encoding: "UTF-8").strip
    svg_icon = '<svg class="svg-icon grey" viewBox="0 0 512 512">' + svg_path_content + "</svg>"

    doc.output = doc.output.gsub(GITHUB_LINK_RE) do
      attrs = Regexp.last_match(1)
      inner = Regexp.last_match(2).strip

      # Skip if already processed (contains an SVG) or opted out with data-no-icon
      if inner.include?("<svg") || attrs.include?("data-no-icon")
        Regexp.last_match(0)
      else
        text = inner.empty? ? "here" : inner
        plain = text.gsub(/<[^>]*>/, "").gsub('"', "&quot;")
        %(<a #{attrs} title="#{plain}">#{svg_icon}\n  #{text}</a>)
      end
    end
  end
end
