FILES_DIR = File.join(__dir__, "../files")

def scrape(filename)
  Page.new(File.read(File.join(FILES_DIR, filename))).scrape()
end

shared_examples "artwork carousel" do
  it "contains artworks" do
    expect(@results).to include("artworks")
    expect(@results["artworks"]).not_to be_empty
  end

  it "has valid artworks" do
    @results["artworks"].each do |a|
      expect(a).to include("name", "link", "image")
      expect(a["name"]).not_to be_empty
    end
  end

  it "has well-formed links" do
    @results["artworks"].each do |a|
      # /search? is Google's, not scraper-guaranteed - asserted to catch a structure change
      expect(a["link"]).to start_with("https://www.google.com/search?")
    end
  end

  it "has valid images" do
    @results["artworks"].each do |a|
      image = a["image"]
      expect(image).not_to be_empty
      # if it's a gif, it's likely a placeholder image - shouldn't be getting those
      expect(image).not_to start_with("data:image/gif")

      if image.start_with?("data:")
        # base64 must survive the \x3d unescape; a stray escape leaves a backslash
        payload = image.split("base64,", 2).fetch(1)
        expect(payload).to match(%r{\A[A-Za-z0-9+/]+=*\z})
      else
        expect(image).to start_with("https://")
      end
    end
  end

  it "has plausible extensions when present" do
    @results["artworks"].select { |a| a.key?("extensions") }.each do |a|
      # unanchored: a year may appear in a range ("1508-1512") or be approximate ("c. 1889")
      expect(a["extensions"].first).to match(/\d{3,4}/)
    end
  end
end

describe "carousel scraper" do
  describe "van gogh paintings" do
    # before :all is ok here since we don't mutate any of these variables - they're read only
    before :all do
      @results = scrape("van-gogh-paintings.html")
      @expected = JSON.parse(File.read(File.join(FILES_DIR, "expected-array.json")))
    end

    include_examples "artwork carousel"

    it "matches expected json" do
      expect(@results).to eq(@expected)
    end
  end

  [
    ["michelangelo sculptures", "michelangelo-sculptures.html"],
    ["picasso artwork",         "pablo-picasso.html"],
    ["claude monet paintings",  "claude-monet-paintings.html"],
  ].each do |label, file|
    describe label do
      before(:all) { @results = scrape(file) }
      include_examples "artwork carousel"
    end
  end

  describe "empty page" do
    it "returns empty artworks gracefully" do
      expect(Page.new("<html></html>").scrape()).to eq({ "artworks" => [] })
    end
  end
end
