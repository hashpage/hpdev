require 'rubygems'
require 'sinatra'

begin
  require 'pbdev'
rescue LoadError
  $: << File.expand_path(File.dirname(__FILE__))
  require 'pbdev'
end

include PBDev
workspace = ENV["PBDEV_WORKSPACE"]

get '/' do
  erb :index
end

get '/widgets' do
  erb :widgets1
end

get '/widgets/:author' do
  erb :widgets2
end

get '/widgets/:author/:name' do
  erb :widgets3
end

get '/skins' do
  erb :skins1
end

get '/skins/:author' do
  erb :skins2
end

get '/skins/:author/:name' do
  erb :skins3
end

get '/engine/*' do
  begin
    resource_path = File.join(workspace, "engine")
    checkout = EngineCheckout.new(resource_path, File.join(workspace, "temp"), "http://localhost:9876/engine")
  rescue NoSuchPathError
    throw :halt, [404, 'file not found']
  end
  
  path = params["splat"][0]
  file_path = checkout.serve(path, :development)
  
  return send_file(file_path, {
    :disposition => 'inline'
  })
end

get '/:kind/:author/:name/*' do
  path = params["splat"][0]
  name = params[:name] # e.g. pbw.tabs
  author = params[:author] # github username e.g. darwin
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
    resource_path = File.join(workspace, kind, author, name)
    checkout = klass.new(resource_path, File.join(workspace, "temp"), "http://localhost:9876/#{kind}/#{author}/#{name}")
  rescue NoSuchPathError
    if name.index("-") then
      # try without prefix
      name = name.split("-")[1..-1].join("-")
    else
      # try with prefix
      name = prefix + "-" + name
    end
    begin
      resource_path = File.join(workspace, kind, author, name)
      checkout = klass.new(resource_path, File.join(workspace, "temp"), "http://localhost:9876/#{kind}/#{author}/#{name}")
    rescue NoSuchPathError
      throw :halt, [404, 'file not found']
    end
  end
  begin
    file_path = checkout.serve(path)
  rescue IntermediateFileError
    throw :halt, [404, 'Requested intermediate resource. This resource won\'t be present on production. See index.js instead.']
  rescue ResourceNotFoundError
    throw :halt, [404, 'resource not found']
  end

  #File.read(file_path)

  return send_file(file_path, {
    :disposition => 'inline'
  })
end