require 'hpdev'
include HPDev

$server_url = "http://localhost:9876"
$workspace = File.expand_path(ENV["HPDEV_WORKSPACE"] || ".")
$mode = (ENV["HPDEV_MODE"] || "development").to_sym

# TODO: add better test for valid workspace
die("Error: '#{$workspace}' is not valid HashPage workspace") unless File.exists?($workspace) && File.directory?($workspace)
die("Error: '#{$mode}' is not recognized mode. Use production or development.") unless $mode==:development || $mode==:production

puts blue("Pagebout")+" dev server in  "+yellow($workspace.to_s)+" ("+magenta($mode.to_s)+") ..."
# clear temp directory
temp = File.join($workspace, "temp")
`rm -rf "#{temp}"`
puts " -> " + green("http://localhost:9876")
