require "nokogiri"
require "json"

class ScraperError < RuntimeError
  
end

class Page
  def initialize(html)
    @html = html
    @doc = Nokogiri::HTML(@html)
    # @lazyImages = 
    # @imageMap = Map.new()
  end

  def scrape()
    _buildLazyLoadMap()
    _scrapeCarousel()
  end

  def _buildLazyLoadMap() 
    # TODO: regex efficiency?
    # this will break if Google swaps the variable order
    results = @html.scan(/var s='(data:[a-z]+\/[a-z]+;base64,[^']+)';var ii=\['([^']+)'\]/)
    if results.empty? then
      # TODO: error type
      # TODO: might not need to be an error, 
      #   not every carousel may have lazy-load images
      raise ScraperError, "no lazily-loaded images found - structure may have changed"
    end

    # nice and simple
    @imageMap = results.to_h { | image, id | [ id, image ] }
  end

  def _scrapeCarousel()
    carousel = @doc.css("[data-attrid=\"kc:/visual_art/visual_artist:works\"]")
    # puts carousel

    # the <a> parent doesn't have any class/id
    # img is more stable, in that case
    _items = carousel.css("img").map do | img |
      # precedence: lazy load > data-src > src
      image = (
        @imageMap[img[:id]] ||
        img['data-src'] ||  # TODO: style
        img['src']
      )

      # a > img, div
      details = img.parent.css("div")
      if details.nil? 
        raise ScraperError, "missing work details"
      end

      # div > div, div
      # TODO: check nil
      name = details.children.first.text
      maybeYear = details.children.last.text

      # extensions = (maybeYear.nil? || maybeYear == name) ? nil : [ maybeYear ]

      item = {
        "name" => name || img[:alt],
        "link" => (
          # remap file://
          "https://www.google.com" +
          # this will break if the image parent changes
          # still works on the example from 2 years ago, 
          # and the current serp
          img.parent[:href]
        ),
        "image" => image.gsub('\x3d', '='), 
      }

      # TODO: there should be a better way to do this
      if !maybeYear.nil? && maybeYear != name then
        item["extensions"] = [ maybeYear ]
      end

      # implicit returns - neat!
      item
    end

    return { "artworks" => _items }
  end
end

# def scrape(html)
#   doc = Nokogiri::HTML(html)

# end 

p = Page.new(
  File.read("./files/van-gogh-paintings.html")
)
# items = p.scrape()
# scrape(File.open("./files/van-gogh-paintings.html"))
puts(JSON.pretty_generate(p.scrape()))