require 'rubygems'
require 'sinatra'

begin
  require 'pbdev'
rescue LoadError
  $: << File.expand_path(File.dirname(__FILE__))
  require 'pbdev'
end

require 'pbdev-server-init'
require 'pbdev-server-helpers'

include PBDev

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
  path = params["splat"][0]
  serve("engine", path)
end

get '/editor/*' do
  path = params["splat"][0]
  serve("editor", path)
end

get '/system/*' do
  path = params["splat"][0]
  serve("system", path)
end

get '/redbug/*' do
  path = params["splat"][0]
  serve("redbug", path)
end

get '/:kind/:author/:name/*' do
  path = params["splat"][0]
  name = params[:name] # e.g. pbw.tabs
  author = params[:author] # github username e.g. darwin
  kind = params[:kind] # e.g. widgets or skins
  serve_widget(path, name, author, kind)
end