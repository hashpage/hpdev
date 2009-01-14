$workspace = File.expand_path(ENV["PBDEV_WORKSPACE"] || ".")
$mode = (ENV["PBDEV_MODE"] || "development").to_sym

# TODO: add better test for valid workspace
die("Error: '#{$workspace}' is not valid PageBout workspace") unless File.exists?($workspace) && File.directory?($workspace)
die("Error: '#{$mode}' is not recognized mode. Use production or development.") unless $mode==:development || $mode==:production

$stderr.puts blue("Pagebout")+" dev server in  #{yellow($workspace)} (#{magenta($mode)}) ..."
$stderr.puts " -> " + green("http://localhost:9876")