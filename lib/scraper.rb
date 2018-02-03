# Gems
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'json'
require 'geocoder'

module Scraper
  class << self

    def display_mode(display_mode)
      @display_mode = display_mode
    end

    # faster testing
    # POOL_LIST_URLS = ["https://web.toronto.ca/data/parks/prd/facilities/indoor-pools/index.html"]
    # Full list
    POOL_LIST_URLS = [ "https://web.toronto.ca/data/parks/prd/facilities/indoor-pools/index.html","https://web.toronto.ca/data/parks/prd/facilities/outdoor-pools/index.html" ]

    Geocoder.configure(:timeout => 10)

    def gather_pool_info
      @pool_urls, pool_names, pool_addresses, pool_links, pool_coordinates = [],[],[],[],[]

      POOL_LIST_URLS.each do |url|
        doc = Nokogiri::HTML(open(url))
        pools = doc.at_css("#pfrBody > div.pfrListing > table > tbody")
        pool_names += pools.css('a').map { |link| link.children.text unless ( link.children.text == "" || link['href'].match(/maps/) ) }.compact
        pool_links += pools.css('a').map { |link| link['href'] if link['href'].match(/parks\/prd\/facilities\/complex/) }.compact
        pool_addresses += gather_pool_addresses(pools)
      end

      array_length_equality = pool_names.length == pool_links.length && pool_links.length == pool_addresses.length
      raise "Pool information lengths are unequal, the website schema has likely changed" unless array_length_equality

      # Geotag pools
      puts "\n--- Scraping pool coordinates ---"
      pool_coordinates = pool_addresses.map { |address| gather_pool_coordinates(address) }

      # Convert Pool Data to Hash
      pool_names.each_with_index do |_, index|
        current_pool = {}
        current_pool[:name] = pool_names[index]
        current_pool[:url] = pool_links[index]
        current_pool[:address] = pool_addresses[index]
        current_pool[:coordinates] = pool_coordinates[index]
        @pool_urls << current_pool
      end

      # Write Hash
      File.open("pool_urls.json","w") do |f|
        f.write(@pool_urls.to_json)
      end
      @pool_urls
    end

    def swim_time_finder(week, lane_swim_row_index)
      week.at_css("tbody").css('tr')[lane_swim_row_index].children
      .map do |el|
        nodes = el.children.find_all(&:text?)
        if nodes.length == 1
          nodes = [el.children.text]
        else
          nodes.map!(&:text)
        end
      end
    end

    def build_pool_schedule_array_from_html(doc)
      weeks = {}

      for i in 0..1 #eventually poll more weeks, possibly 4 of available 7
        week = doc.at_css("#dropin_Swimming_#{i}")
        !week.nil?? week_dates = week.at_css('tr').children.map(&:text) : next

        !week_dates.nil?? lane_swim_row_index = week.at_css("tbody").css('tr').find_index { |el| el.text=~ /Lane Swim/ } : next

        if !lane_swim_row_index.nil?
          week_lane_swim_times = swim_time_finder(week, lane_swim_row_index)
          weeks.merge!(week_dates.zip(week_lane_swim_times).to_h)
        end
      end

      # remove days with no swim times
      weeks.delete_if { |_, time| time == [" "] || time == [] }
    end

    def gather_pool_addresses(pools)
      address_index = pools.css('td').length / pools.css('tr').length

      pools.css('td').each_with_object([]).with_index do |(node, pool_addresses), index|
        # Address is always second column, table width varies for indoor vs. outdoor
        if index % address_index == 1
          pool_addresses << node.text
        end
      end
    end

    def gather_pool_coordinates(address)
      if @display_mode == "verbose"
        puts "Geocoding: #{address}"
      else
        print "."
      end

      coordinates_arr = Geocoder.coordinates("#{address}, Toronto")

      # To avoid triggering google API limit of 50 queries per second
      sleep(0.02)
      if coordinates_arr
        return { latitude: coordinates_arr[0], longitude: coordinates_arr[1] }
      else
        puts "Retrying: #{address}..."
        gather_pool_coordinates(address)
      end
    end

    #####Parse Weekly Leisure Swim Data#####
    def gather_pool_swim_times
      begin
        @pool_urls ||= JSON.parse(File.read('pool_urls.json'), symbolize_names: true)
      rescue
        puts "Couldn't open pool_info, run scrape -f or run in path with pool_urls.json file"
        exit
      end

      puts "\n--- Scraping pool swim times ---"
      @pool_urls.each do |pool|
        if @display_mode == "verbose"
          puts "Scraping: " + pool[:name]
        else
          print "."
        end
        url = "https://www.toronto.ca" + pool[:url]
        doc = Nokogiri::HTML(open(url))
        pool[:times] = build_pool_schedule_array_from_html(doc)
      end

      File.open("pools_data.json","w") do |f|
        f.write(@pool_urls.to_json)
        puts "\nWriting pools_data.json complete"
      end

      @pool_urls
    end

    def gather_pool_program_cost_status
      @pools = JSON.parse(File.read('pools_data.json'), symbolize_names: true)

      page = "https://www.toronto.ca/explore-enjoy/recreation/free-lower-cost-recreation-options/"
      doc = Nokogiri::HTML(open(page))
      free_facility_article = doc.at_css("#collapse-centres-where-programs-are-free")
      links = free_facility_article.css('a')
      all_hrefs = links.map { |link| link.attribute('href').to_s }.uniq.sort.delete_if { |href| href.empty? }

      free_facility_urls_regexed = all_hrefs.keep_if{ |href| href.match("\/parks/prd/facilities/complex\w*") }
                                            .map{ |url| url.match(/\/parks\/prd\/facilities\/complex\/\d*/).to_s }

      @pools.each do |pool|
        pool_url_regex = pool[:url].match(/\/parks\/prd\/facilities\/complex\/\d*/).to_s
        match = free_facility_urls_regexed.find{ |e| pool_url_regex == e }
        pool[:free_swim] = match ? true : false
      end

      File.open("pools_data.json","w") do |f|
        f.write(@pools.to_json)
        puts "Writing program cost status to pools_data.json complete"
      end

      @pools
    end

  end
end

# Todo
# add a test suite
# remind self how to log name of vars while blown up (smaller method with info passed in probably!)
#start displaying, filtering?
#maybe transform date save
