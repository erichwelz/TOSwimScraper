# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.authors       = ["Erich Welz"]
  gem.email         = "erichwelz@gmail.com"
  gem.description   = "Scraper to grab City of Toronto lane swim data creating a JSON file with geotagged pools"
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/erichwelz/TOSwim"

  gem.files         = ["lib/scraper.rb"]
  gem.executables   << 'scrape'
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "TOSwimScraper"
  gem.require_paths = ["lib"]
  gem.version       = '0.1.7'

  gem.add_dependency "bundler", "~> 1.3"
  gem.add_dependency "geocoder", "~> 1.2"
  gem.add_dependency 'json', '~> 1.8', '>= 1.8.3'
  gem.add_dependency "nokogiri", "~> 1.6"
  gem.add_dependency "pry", "~> 0.10"
end
