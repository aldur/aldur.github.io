# frozen_string_literal: true

module Jekyll
  # Generator that creates an llms.txt file at the site root.
  # See https://llmstxt.org/ for the specification.
  class LlmsTxtGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      site.static_files << LlmsTxtFile.new(site, build_content(site))
    end

    private

    def build_content(site)
      lines = []

      lines << "# #{site.config["title"]}"
      lines << ""

      if (description = site.config.dig("about", "long") || site.config["description"])
        lines << "> #{description}"
        lines << ""
      end

      lines << "## Articles"
      lines << ""
      sorted_posts(site).each do |post|
        lines << format_entry(post)
      end

      if site.collections.key?("micros")
        lines << ""
        lines << "## Micros"
        lines << ""
        sorted_micros(site).each do |micro|
          lines << format_entry(micro)
        end
      end

      lines << ""
      lines.join("\n")
    end

    def sorted_posts(site)
      site.posts.docs.sort_by { |p| p.date }.reverse
    end

    def sorted_micros(site)
      site.collections["micros"].docs.sort_by { |m| m.date }.reverse
    end

    def format_entry(doc)
      title = doc.data["title"]
      entry = "- [#{title}](#{doc.url})"
      if (excerpt = doc.data["description"] || plain_excerpt(doc))
        entry += ": #{excerpt}"
      end
      entry
    end

    def plain_excerpt(doc)
      return nil unless doc.data["excerpt"]

      text = doc.data["excerpt"].to_s
        .gsub(/<[^>]+>/, "")  # strip HTML tags
        .gsub(/\s+/, " ")     # collapse whitespace
        .strip
      text.empty? ? nil : text
    end
  end

  class LlmsTxtFile < StaticFile
    def initialize(site, content)
      @site = site
      @content = content
      @base = site.source
      @dir = "/"
      @name = "llms.txt"
      @collection = nil
      @relative_path = "/llms.txt"
    end

    def write(dest)
      dest_path = destination(dest)
      FileUtils.mkdir_p(File.dirname(dest_path))
      File.write(dest_path, @content, encoding: "UTF-8")
      true
    end

    def modified?
      true
    end

    def relative_path
      @relative_path
    end

    def destination(dest)
      File.join(dest, @name)
    end

    def url
      "/#{@name}"
    end
  end
end
