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
  def setup
    Scraper.display_mode("concise")
  end

  def test_gather_pool_info
    VCR.use_cassette("get_pool_info") do
      pools = Scraper.gather_pool_info
      assert pools.is_a?(Array)
      assert_operator pools.length, :>, 50

      pool = pools.last
      assert_operator pool[:url].length, :>, 1
      assert_operator pool[:address].length, :>, 1
      assert_operator pool[:name].length, :>, 1
      
      assert pool[:coordinates][:latitude].is_a?(Float)
      assert pool[:coordinates][:longitude].is_a?(Float)
    end
  end
end
