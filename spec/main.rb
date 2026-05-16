describe "carousel scraper" do
  describe "van gogh paintings" do
    before :all do
      page = Page.new(
        File.read(File.join(__dir__, "../files/van-gogh-paintings.html"))
      )
      @results = page.scrape()

      expected_data = File.read(File.join(__dir__, "../files/expected-array.json"))
      @expected = JSON.parse(expected_data)
    end

    # the golden test
    it "matches expected json" do
      expect(@results).to eq(@expected)
    end

    # practically speaking, this file doesn't need any more tests
    #   we have the expected result, we checked against it, it matches
    # however: for the sake of exercise, here are some other useful tests
  end

  describe "michelangelo sculptures" do
    before :all do
      page = Page.new(
        File.read(File.join(__dir__, "../files/michelangelo-sculptures.html"))
      )
      @results = page.scrape()
    end

    it "contains artworks" do
      expect(@results).to include("artworks")
      expect(@results["artworks"].length).to be > 0
    end

    it "has valid artworks" do
      expect(@results["artworks"]).to all(include("name", "link", "image"))
    end
  end
end