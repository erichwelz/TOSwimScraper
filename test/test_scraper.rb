require 'minitest/autorun'
require 'scraper'
require 'vcr'


VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock # or :fakeweb
end

class ScraperTest < Minitest::Test

  def test_swim_time_finder
    #
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


  def test_gather_pool_swim_times
    VCR.use_cassette("gather_pool_times") do
      swim_times = Scraper.gather_pool_swim_times

      assert swim_times.is_a?(Array)
      assert_operator swim_times.length, :>, 50

      swim_time = swim_times[0]
      assert_operator swim_time[:url].length, :>, 1
      assert_operator swim_time[:address].length, :>, 1
      assert_operator swim_time[:name].length, :>, 1
      assert swim_time[:coordinates][:latitude].is_a?(Float)
      assert swim_time[:coordinates][:longitude].is_a?(Float)

      assert swim_time[:times].is_a?(Hash)
      assert_operator swim_time[:times].length, :>, 1
    end
  end

  def test_gather_pool_cost_status
    VCR.use_cassette("gather_pool_cost_status") do
      cost_statuses = Scraper.gather_pool_program_cost_status

      assert cost_statuses.is_a?(Array)
      assert_operator cost_statuses.length, :>, 50
      cost_status = cost_statuses.last

      # assert is a boolean, not nil
      assert_equal !!cost_status[:free_swim], cost_status[:free_swim]
    end
  end

end
