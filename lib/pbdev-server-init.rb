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

$workspace = File.expand_path(ENV["PBDEV_WORKSPACE"] || ".")
$mode = (ENV["PBDEV_MODE"] || "development").to_sym

# TODO: add better test for valid workspace
die("Error: '#{$workspace}' is not valid PageBout workspace") unless File.exists?($workspace) && File.directory?($workspace)
die("Error: '#{$mode}' is not recognized mode. Use production or development.") unless $mode==:development || $mode==:production

$stderr.puts blue("Pagebout")+" dev server in  #{yellow($workspace)} (#{magenta($mode)}) ..."
$stderr.puts " -> " + green("http://localhost:9876")