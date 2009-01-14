require 'rubygems'
require 'fileutils'
require 'grit/lib/grit.rb'

OSX = PLATFORM =~ /darwin/
WIN = PLATFORM =~ /win32/
NIX = !(OSX || WIN)

# http://kpumuk.info/ruby-on-rails/colorizing-console-ruby-script-output/
begin
  require 'Win32/Console/ANSI' if WIN
rescue LoadError
  raise 'Run "gem install win32console" to use terminal colors on Windows'
end

def colorize(text, color_code)
  "#{color_code}#{text}\e[0m"
end

def red(text); colorize(text, "\e[31m"); end
def green(text); colorize(text, "\e[32m"); end
def yellow(text); colorize(text, "\e[33m"); end
def blue(text); colorize(text, "\e[34m"); end
def magenta(text); colorize(text, "\e[35m"); end
def azure(text); colorize(text, "\e[36m"); end
def white(text); colorize(text, "\e[37m"); end
def black(text); colorize(text, "\e[30m"); end

def die(s)
  $stderr.puts red(s)
  exit(1)
end

class Loggerx
  def debug(s)
    #$stderr.puts yellow(s)
  end

  def info(s)
    $stderr.puts blue(s)
  end

  def fatal(s)
    $stderr.puts red(s)
  end
end

class PBC
  attr :logger
  
  def initialize()
    @logger = Loggerx.new
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

PBDEV_LIB_LOCATION = File.dirname(File.expand_path(__FILE__))