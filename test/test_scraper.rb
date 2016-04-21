require 'minitest/autorun'
require 'scraper'
require 'vcr'


VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock # or :fakeweb
end

class ScraperTest < Minitest::Test

  def test_simple_doubler
    assert_equal 10, Scraper.simple_equal(5)
  end
end

class VCRTest < Minitest::Test
  def test_gather_pool_urls
    VCR.use_cassette("get_pool_urls") do
      pools = Scraper.gather_pool_urls

    end
  end
end
