require "rubygems"

require "bundler"
Bundler.setup


require 'rspec'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'vinquery'

RSpec.configure do |config|

end