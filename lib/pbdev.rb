PBDEV_LIB_LOCATION = File.dirname(File.expand_path(__FILE__))

require 'rubygems'
require 'fileutils'
require 'grit/lib/grit.rb'

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

require 'pbdev/utils.rb'

require 'pbdev/cssmin.rb'
require 'pbdev/manifest.rb'
require 'pbdev/bundle.rb'
require 'pbdev/builder.rb'

require 'pbdev/errors.rb'
require 'pbdev/checkout.rb'
require 'pbdev/repo.rb'
require 'pbdev/widget.rb'
require 'pbdev/skin.rb'
require 'pbdev/engine.rb'
require 'pbdev/editor.rb'
require 'pbdev/system.rb'
require 'pbdev/redbug.rb'
require 'pbdev/front.rb'
