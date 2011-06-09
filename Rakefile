$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'vinquery/version'

task :build do
  system "gem build vinquery.gemspec"
end
 
task :release => :build do
  system "gem push vinquery-#{Vinquery::VERSION}"
end