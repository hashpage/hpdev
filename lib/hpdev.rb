HPDEV_LIB_LOCATION = File.dirname(File.expand_path(__FILE__))

require 'rubygems'
require 'fileutils'
begin
  require 'hpricot'
rescue
  raise "Do: sudo gem install hpricot"
end
require 'grit'
#Grit.debug = true

unless defined? OSX then
  OSX = PLATFORM =~ /darwin/
  WIN = PLATFORM =~ /win32/
  NIX = !(OSX || WIN)
end

begin
  require 'term/ansicolor'
  include Term::ANSIColor
rescue LoadError
  raise 'Run "gem install term-ansicolor"'
end
# http://kpumuk.info/ruby-on-rails/colorizing-console-ruby-script-output/
if WIN then
  begin
    require 'win32console'
    include Win32::Console::ANSI
  rescue LoadError
    raise 'Run "gem install win32console" to use terminal colors on Windows'
  end
end

def die(s)
  puts red(s)
  exit(1)
end

class PBLogger
  def debug(s)
    #puts yellow(s)
  end

  def info(s)
    puts blue(s)
  end

  def fatal(s)
    puts red(s)
  end
end

class PBC
  attr :logger
  
  def initialize()
    @logger = PBLogger.new
  end
end

PB = PBC.new

require 'hpdev/utils.rb'

require 'hpdev/cssmin.rb'
require 'hpdev/manifest.rb'
require 'hpdev/bundle.rb'
require 'hpdev/builder.rb'

require 'hpdev/errors.rb'
require 'hpdev/checkout.rb'
require 'hpdev/repo.rb'
require 'hpdev/widget.rb'
require 'hpdev/skin.rb'
require 'hpdev/engine.rb'
require 'hpdev/editor.rb'
require 'hpdev/system.rb'
require 'hpdev/redbug.rb'
require 'hpdev/front.rb'
