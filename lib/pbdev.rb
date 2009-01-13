require 'rubygems'
require 'fileutils'
require 'grit/lib/grit.rb'

class Loggerx
  def debug(s)
    puts s
  end

  def fatal(s)
    $stderr.puts s
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

PBDEV_LIB_LOCATION = File.dirname(File.expand_path(__FILE__))