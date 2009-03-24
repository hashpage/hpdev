require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "hpdev"
    s.summary = "HashPage development support"
    s.email = "antonin@hildebrand.cz"
    s.homepage = "http://github.com/darwin/hpdev"
    s.description = "Various tools for HashPage developers"
    s.authors = ["Antonin Hildebrand"]
    s.add_dependency('grit')
    s.add_dependency('sinatra')
    s.add_dependency('hpricot')
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install hashpage-hpdev -s http://gems.github.com"
end

task :default => :rcov
