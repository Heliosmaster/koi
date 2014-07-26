require 'sinatra'
require 'sinatra/cookies'
require 'data_mapper'
require 'haml'
require 'date'
require 'csv'
require 'coffee-script'
require 'therubyracer'

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

before do
  @user ||= User.get(session[:user])
end

get '/' do
  @user ||= User.get(session[:user])
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
  haml :form, layout: :layout
end

post '/transaction/add' do
  @user ||= User.get(session[:user])
  Transaction.create_from_params(params[:transaction], @user)
  @user.update_values
  redirect to '/'
end

get '/transaction/import' do
  haml :import, layout: :layout
end

post '/transaction/import' do
  @user ||= User.get(session[:user])
  Transaction.create_from_csv(params[:file][:tempfile], @user, params[:shared])
  @user.update_values
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
  transactions_ym = @user.transactions_by_year_month
  @transactions = transactions_ym[year][month]
  haml :bulk_edit_month, layout: :layout
end

post '/transaction/bulk_edit' do
  params[:transaction].each do |k,v|
    Transaction.get(k).update_from_params(v)
  end
  @user ||= User.get(session[:user])
  @user.update_values
  redirect to "/"
end


# Modifying a transaction
get '/transaction/:id' do
  @transaction = Transaction.get(params[:id])
  haml :edit, layout: :layout
end

post '/transaction/:id/toggle_shared' do
  transaction = Transaction.get(params[:id])
  transaction.update(shared: !transaction.shared)
  transaction.user.update_values
end

put '/transaction/:id' do
  transaction = Transaction.get(params[:id])
  transaction = update_from_params(params[:transaction])
  transaction.user.update_values
  redirect to "/"
end

delete '/transaction/:id' do
  transaction = Transaction.get(params[:id])
  user = transaction.user
  transaction.destroy
  user.update_values
  redirect to "/"
end


# Balance-related stuff

get '/balance' do
  @transactions = Transaction.all_shared_into_hash
  @month_names_count = []
  @transactions.each do | year, t_by_year |
    t_by_year.each do | month, t_by_year_month |
      @month_names_count << {
        name: Date.parse("#{year}-#{month}-01").strftime("%B %Y"),
        url: "/balance/#{year}/#{month}",
        count: t_by_year_month.length }
    end
  end
  @stats = User.expenses_and_differences

  haml :balance, layout: :layout
end

get '/balance/:year/:month' do
  start_day = Date.parse("#{params[:year]}-#{params[:month]}-01")
  end_day = start_day.next_month-1
  @transactions = Transaction.all(date: (start_day..end_day), shared: true)
  month_year = start_day.strftime("%B %Y")
  @title = "Shared transactions for #{month_year}"
  haml :balance_list, layout: :layout
end

get '/balance/all' do
  @transactions = Transaction.all(shared: true)
  @title = "Total shared transactions"
  haml :balance_list, layout: :layout
end

# Javascript
get '/home.js' do
  coffee :home
end
