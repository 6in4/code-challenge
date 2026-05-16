describe "carousel scraper" do
  describe "van gogh paintings" do
    before :all do
      # TODO: Fix this
      @page = Page.new(
        File.read(File.join(__dir__, "../files/van-gogh-paintings.html"))
      )
      @results = @page.scrape()

      expected_data = File.read(File.join(__dir__, "../files/expected-array.json"))
      @expected = JSON.parse(expected_data)
    end

    # it "matches expected length" do
    #   expect(@results.length).to eq(@expected.length)
    # end

    it "matches expected array" do
      expect(@results).to eq(@expected) # TODO:
    end
  end
end
