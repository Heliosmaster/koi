require 'sinatra'
require 'sinatra/cookies'
require 'data_mapper'
require 'haml'
require 'date'
require 'csv'

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
  if @user
    @transactions = @user.transactions
    @transactions_by_year_month = @user.transactions_by_year_month
    @last_import = @user.last_import
  end

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

get '/transaction/import' do
  @user ||= User.get(session[:user])
  haml :import, layout: :layout
end

post '/transaction/import' do
  @user ||= User.get(session[:user])
  Transaction.create_from_csv(params[:file][:tempfile],@user,params[:shared])
  redirect to '/'
end

get '/transaction/bulk_edit' do
  @user ||= User.get(session[:user])
  @transactions = @user.transactions_by_year_month
  haml :bulk_edit, layout: :layout
end

get '/transaction/bulk_edit/:year/:month' do
  @user ||= User.get(session[:user])
  year = params[:year].to_i
  month = params[:month].to_i
  p "YM #{year} #{month}"
  transactions_ym = @user.transactions_by_year_month
  @transactions = transactions_ym[year][month]
  haml :bulk_edit_month, layout: :layout
end

post '/transaction/bulk_edit' do
  @user ||= User.get(session[:user])
  params[:transaction].each do |k,v|
    Transaction.get(k).update_from_params(v)
  end
  redirect to "/"
end

get '/transaction/:id' do
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

get '/balance' do
  @transactions = Transaction.all(shared: true)
  @stats = {}
  average = User.average_expenses
  User.all.each do |user|
    @stats[user.id] = {}
    expenses = user.total_expenses
    @stats[user.id][:expenses] = expenses
    @stats[user.id][:difference] = (expenses-average).round(2)
  end
  haml :balance, layout: :layout
end
