require 'sinatra'
require 'sinatra/cookies'
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

enable :sessions
set :session_secret, "supersecretphrase"

get '/' do
  @user = User.get(session[:user])
  haml :home, layout: :layout
end

post '/select_user' do
  @user = User.first(name: params["user_select"])
  session[:user] = @user ? @user.id : nil
  redirect to '/'
end

get '/transaction/add' do
  redirect to '/'
end

get '/transaction/import' do
  redirect to '/'
end
