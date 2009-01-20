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
  redirect "#{params[:name]}/master"
end

get '/widgets/:author/:name/master' do
  erb :widgets3
end

get '/skins' do
  erb :skins1
end

get '/skins/:author' do
  erb :skins2
end

get '/skins/:author/:name' do
  redirect "#{params[:name]}/master"
end

get '/skins/:author/:name/master' do
  erb :skins3
end

get '/code' do
  erb :code1
end

get '/code/:package/master' do
  erb :code2
end

get '/code/:package/master/*' do
  path = params["splat"][0]
  package = params[:package]
  serve(package, path)
end

get '/:kind/:author/:name/master/*' do
  path = params["splat"][0]
  name = params[:name] # e.g. pbw.tabs
  author = params[:author] # github username e.g. darwin
  kind = params[:kind] # e.g. widgets or skins
  serve_widget(path, name, author, kind)
end