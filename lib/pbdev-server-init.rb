require 'pbdev'
include PBDev

$server_url = "http://localhost:9876"
$workspace = File.expand_path(ENV["PBDEV_WORKSPACE"] || ".")
$mode = (ENV["PBDEV_MODE"] || "development").to_sym

# TODO: add better test for valid workspace
die("Error: '#{$workspace}' is not valid PageBout workspace") unless File.exists?($workspace) && File.directory?($workspace)
die("Error: '#{$mode}' is not recognized mode. Use production or development.") unless $mode==:development || $mode==:production

puts blue("Pagebout")+" dev server in  "+yellow($workspace.to_s)+" ("+magenta($mode.to_s)+") ..."
# clear temp directory
temp = File.join($workspace, "temp")
`rm -rf "#{temp}"`
puts " -> " + green("http://localhost:9876")
