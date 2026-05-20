require "nokogiri"
require "json"

class ScraperError < RuntimeError
  # left intentionally empty; exists for semantic error handling/catching
end

class Page
  def initialize(html)
    @html = html
    @doc = Nokogiri::HTML(@html)
    @image_map = get_lazy_load_map
  end

  # public entrypoint; extend here for additional block types
  def scrape
    scrape_carousel
  end

  # search for images that are lazily loaded
  # these images are stored in <script> tags
  # however: not all images are lazily loaded
  private def get_lazy_load_map
    # this will break if Google swaps the variable order
    results = @html.scan(/var s='(data:[a-z]+\/[a-z]+;base64,[^']+)';var ii=\['([^']+)'\]/)
    results.to_h { | image, id | [ id, image ] }
  end

  private def scrape_carousel
    # couldn't find any other carousel type -
    #   everything else (albums, films, books) use grids instead of carousels
    #   grids may look functionally identical, but they are semantically different
    #   + the return key in expected-array.json is { "artworks": [] }
    # that's why this selector is strict
    carousel = @doc.css("[data-attrid=\"kc:/visual_art/visual_artist:works\"]")

    # the <a> parent doesn't have any class/id
    # img is more stable, in that case
    items = carousel.css("img").map do | img |
      # precedence: lazy load > data-src > src
      image = (
        @image_map[img[:id]] ||
        img['data-src'] ||
        img['src']
      )

      raise ScraperError, 'missing image data - structure changed?' if image.nil?
      raise ScraperError, 'placeholder gif detected - structure changed?' if image.start_with?("data:image/gif;base64,")

      # a > div > (name_div, year_div)
      name_div, year_div = img.parent.css("div > div")
      raise ScraperError, "missing work details" if name_div.nil?

      name = name_div.text.empty? ? img[:alt] : name_div.text
      raise ScraperError, "missing artwork name" if name.nil? || name.empty?
      year = year_div&.text || ""

      # this will break if the image parent tag changes
      # but it works on the example from 2 years ago, 
      # and it works on the current serp
      link_el = img.ancestors("a").first
      raise ScraperError, "missing link element" if link_el.nil? || link_el[:href].to_s.empty?
      link = "https://www.google.com" + link_el[:href]

      {
        "name" => name,
        "extensions" => year.empty? ? nil : [year],
        "link" => link,
        # script tags contain `=` base64 padding as `\x3d` instead - unescape only that
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
    Page.new(File.read(ARGV[0])).scrape
  )
end
