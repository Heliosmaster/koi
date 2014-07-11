require 'sinatra'
require 'data_mapper'
require 'haml'
require 'date'


require_relative 'models'
# If you want the logs displayed you have to do this before the call to setup
DataMapper::Logger.new($stdout, :debug)
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/kroisos.db")
DataMapper.finalize.auto_upgrade!

User.create(name: "Davide")
User.create(name: "Kleopatra")

get '/' do
  haml :home, layout: :layout
end
