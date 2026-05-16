require "nokogiri"
require "json"

class ScraperError < RuntimeError
  
end

class Page
  def initialize(html)
    @html = html
    @doc = Nokogiri::HTML(@html)
  end

  def scrape()
    build_lazy_load_map()
    scrape_carousel()
  end

  # search for images that are lazily loaded
  # these images are stored in <script> tags
  # however: not all images are lazily loaded
  private def build_lazy_load_map () 
    # this will break if Google swaps the variable order
    results = @html.scan(/var s='(data:[a-z]+\/[a-z]+;base64,[^']+)';var ii=\['([^']+)'\]/)

    # nice and simple
    @imageMap = results.to_h { | image, id | [ id, image ] }
  end

  private def scrape_carousel()
    # couldn't find any other carousel type -
    #   everything else (albums, films, books) use grids instead of carousels
    #   grids may look functionally identical, but they are semantically different
    carousel = @doc.css("[data-attrid=\"kc:/visual_art/visual_artist:works\"]")

    # the <a> parent doesn't have any class/id
    # img is more stable, in that case
    items = carousel.css("img").map do | img |
      # precedence: lazy load > data-src > src
      image = (
        @imageMap[img[:id]] ||
        img['data-src'] ||
        img['src']
      )

      raise ScraperError, 'missing image data - structure changed?' if image.nil?
      raise ScraperError, 'placeholder gif detected - structure changed?' if image.start_with?("data:image/gif;base64,")

      # a > img, div
      details = img.parent.css("div")
      raise ScraperError, "missing work details" if details.children.length == 0

      # div > div, div
      name = details.children.first.text
      maybe_year = details.children.last.text # TODO: how to do this better? this may or may not be present

      # implicit returns - neat!
      {
        "name" => name != "" ? name : img[:alt],
        "extensions" => maybe_year != name ? [ maybe_year ] : nil,
        "link" => (
          # remap `file://` to match expected
          "https://www.google.com" +
          # this will break if the image parent changes
          # but it works on the example from 2 years ago, 
          # and it works on the current serp
          img.parent[:href]
        ),
        "image" => image.gsub('\x3d', '='),
      }.compact
    end

    { "artworks" => items }
  end
end

if $0 == __FILE__ 
  if ARGV[0].nil?
    puts "USAGE: #{$0} <serp.html>"
    exit 1
  end

  puts JSON.pretty_generate(
    Page.new(
      File.read(ARGV[0])
    ).scrape()
  )
end
