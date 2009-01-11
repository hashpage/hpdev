require 'rubygems'
require 'sinatra'

begin
  require 'pbdev'
rescue LoadError
  $: << File.dirname(__FILE__)
  require 'pbdev'
end

include PBDev
workspace = ENV["PBDEV_WORKSPACE"]

get '/:kind/:name/*' do
  path = params["splat"][0]
  name = params[:name] # e.g. pbw.tabs
  kind = params[:kind] # e.g. widgets or skins

  case kind
  when "widgets"
    klass = WidgetCheckout
    prefix = "pbw"
  when "skins"
    klass = SkinCheckout
    prefix = "pbs"
  else
    throw :halt, [404, 'bad resource kind']
  end

  begin 
    resource_path = File.join(workspace, kind, name)
    checkout = klass.new(resource_path, File.join(workspace, "temp"), "#{kind}/#{name}")
  rescue NoSuchPathError
    if name.index("-") then
      # try without prefix
      name = name.split("-")[1..-1].join("-")
    else
      # try with prefix
      name = prefix + "-" + name
    end
    begin
      resource_path = File.join(workspace, kind, name)
      checkout = klass.new(resource_path, File.join(workspace, "temp"), "#{kind}/#{name}")
    rescue NoSuchPathError
      puts "Resource is missing: #{resource_path}"
      throw :halt, [404, 'not found']
    end
  end
  begin
    file_path = checkout.serve(path)
  rescue IntermediateFileError
    throw :halt, [404, 'requested intermediate resource']
  rescue ResourceNotFoundError
    throw :halt, [404, 'resource not found']
  end

  #File.read(file_path)

  return send_file(file_path, {
    :disposition => 'inline'
  })
end