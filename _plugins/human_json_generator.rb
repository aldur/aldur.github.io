# frozen_string_literal: true

require "json"

module Jekyll
  # Generator that creates a human.json file at the site root.
  # See https://codeberg.org/robida/human.json for the specification.
  class HumanJsonGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      site.static_files << HumanJsonFile.new(site, build_content(site))
    end

    private

    def build_content(site)
      data = {
        "version" => "0.1.1",
        "url" => site.config["url"]
      }

      if (vouches = site.config.dig("human_json", "vouches"))
        data["vouches"] = vouches.map do |v|
          { "url" => v["url"], "vouched_at" => v["vouched_at"].to_s }
        end
      end

      JSON.pretty_generate(data) + "\n"
    end
  end

  class HumanJsonFile < StaticFile
    def initialize(site, content)
      @site = site
      @content = content
      @base = site.source
      @dir = "/"
      @name = "human.json"
      @collection = nil
      @relative_path = "/human.json"
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
