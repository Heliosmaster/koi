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
enable :method_override

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
  @user = User.get(session[:user])
  haml :form, layout: :layout
end

post '/transaction/add' do
  @user ||= User.get(session[:user])
  Transaction.create_from_params(params[:transaction],@user)
  redirect to '/'
end

get '/transaction/:id/edit' do
  @transaction = Transaction.get(params[:id])
  haml :edit, layout: :layout
end

put '/transaction/:id' do
  Transaction.get(params[:id]).update_from_params(params[:transaction])
  redirect to "/"
end

delete '/transaction/:id' do
  Transaction.get(params[:id]).destroy
  redirect to "/"
end

get '/transaction/import' do
  redirect to '/'
end
