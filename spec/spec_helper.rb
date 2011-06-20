$:.unshift(File.dirname(__FILE__) + '/../lib')
require "rubygems"
if ENV["COVERAGE"]
  require 'simplecov'  
  SimpleCov.start 'rails' 
end

require "bundler"
Bundler.setup


require 'rspec'
require 'webmock/rspec'

require 'vinquery'

RSpec.configure do |config|

end