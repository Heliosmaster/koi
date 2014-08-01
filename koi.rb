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

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/koi.db")
DataMapper.finalize.auto_upgrade!

User.create(name: "Davide")
User.create(name: "Kleopatra")

enable :sessions
enable :method_override

set :session_secret, "supersecretphrase"

before do
  @user ||= User.get(session[:user])
  if @user
    @total_shared_expense ||= @user.total_shared_expenses
    @difference ||= @user.difference
  end
end

get '/' do
  if @user
    @transactions = @user.transactions
    @transactions_by_year_month = @user.transactions_by_year_month
    @last_import_date ||= @user.last_import_date
    @last_import_id ||= @user.last_import_id
  end

  haml :home, layout: :layout
end

get '/transactions/show/:year/:month' do
  @year = params[:year].to_i
  @month = params[:month].to_i
  @pretty_month_year = Date.parse("#{@year}-#{@month}-01").strftime("%B %Y")
  @transactions = @user.transactions_by_year_month[@year][@month]
  haml :year_month
end

get '/transactions/show/:year' do
  @year = params[:year].to_i
  @transactions = @user.transactions_by_year_month[@year]
  haml :year
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
  Transaction.create_from_params(params[:transaction], @user)
  @user.update_values
  redirect to '/'
end

get '/transaction/csv' do
  haml :csv, layout: :layout
end

post '/transaction/import' do
  @errors = Transaction.create_from_csv(params[:file][:tempfile], @user, params[:shared])
  @user.update_values
  if @errors.empty?
    redirect to '/'
  else
    haml :conflict, layout: :layout
  end
end

post '/transaction/conflict' do
  @errors = []
  if params["transaction"].nil?
    redirect to "/"
  else
    params["transaction"].each do |index, params_for_transaction|
      if params_for_transaction["id"]
        p "UPDATING #{params_for_transaction["id"]}"
        error = Transaction.get(params_for_transaction["id"]).update_from_params(params_for_transaction)
      else
        p "CREATING NEW"
        error = Transaction.create_from_params(params_for_transaction, @user)
      end
      @errors << error unless error.nil?
    end
    @user.update_values
    if @errors.empty?
      redirect to '/'
    else
      haml :conflict, layout: :layout
    end
  end

end

post '/transaction/bulk_edit' do
  @errors = []
  params[:transaction].each do |k,v|
    error = Transaction.get(k).update_from_params(v)
    @errors << error unless error.nil?
  end
  p @errors
  @user.update_values
  if @errors.empty?
    redirect to "/"
  else
    haml :conflict, layout: :layout
  end
end

put '/transaction/:id' do
  transaction = Transaction.get(params[:id])
  error = transaction.update_from_params(params[:transaction])
  transaction.user.update_values
  if error
    @errors = [error]
    haml :conflict, layout: :layout
  else
    redirect to "/"
  end
end


post '/transaction/export' do
  attachment "Koi-#{Date.today}.txt"
  @user.export_to_csv
  #  redirect to '/'
end

get '/transaction/bulk_edit' do
  @transactions = @user.transactions_by_year_month
  haml :bulk_edit, layout: :layout
end

get '/transaction/bulk_edit/:year/:month' do
  year = params[:year].to_i
  month = params[:month].to_i
  @pretty_month_year = Date.parse("#{year}-#{month}-01").strftime("%B %Y")
  transactions_ym = @user.transactions_by_year_month
  @transactions = transactions_ym[year][month]
  haml :bulk_edit_month, layout: :layout
end

get '/transaction/bulk_edit/:year' do
  year = params[:year].to_i
  month = params[:month].to_i
  transactions_ym = @user.transactions_by_year_month
  @transactions = transactions_ym[year]
  haml :bulk_edit_year, layout: :layout
end



get '/transaction/show' do
  @transactions = @user.transactions_by_year_month
  haml :show
end

get '/transaction/search' do
  @transactions = Transaction.all(:date.gte => params[:start_date], :date.lte => params[:end_date])
  haml :show_search, layout: :layout
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

get '/input.js' do
  coffee :input
end

get '/conflict.js' do
  coffee :conflict
end

# Partials for in-place update of values

get '/difference' do
  @user.difference.to_s
end

get '/monthly/:year/:month/shared_balance' do
  start_day = Date.parse("#{params[:year]}-#{params[:month]}-01")
  end_day = start_day.next_month-1
  @user.transactions(date: (start_day..end_day), shared: true).map(&:amount).sum.to_s
end

get '/monthly/:year/:month/shared_income' do
  start_day = Date.parse("#{params[:year]}-#{params[:month]}-01")
  end_day = start_day.next_month-1
  "+#{@user.transactions(date: (start_day..end_day),shared: true, :amount.gte => 0).map(&:amount).sum}"
end

get '/monthly/:year/:month/shared_expense' do
  start_day = Date.parse("#{params[:year]}-#{params[:month]}-01")
  end_day = start_day.next_month-1
  @user.transactions(date: (start_day..end_day), shared: true, :amount.lt => 0).map(&:amount).sum.to_s
end

get '/yearly/:year/shared_balance' do
  start_day = Date.parse("#{params[:year]}-01-01")
  end_day = start_day.next_year-1
  @user.transactions(date: (start_day..end_day), shared: true).map(&:amount).sum.to_s
end

get '/yearly/:year/shared_income' do
  start_day = Date.parse("#{params[:year]}-01-01")
  end_day = start_day.next_year-1
  "+#{@user.transactions(date: (start_day..end_day),shared: true, :amount.gte => 0).map(&:amount).sum}"
end

get '/yearly/:year/shared_expense' do
  start_day = Date.parse("#{params[:year]}-01-01")
  end_day = start_day.next_year-1
  @user.transactions(date: (start_day..end_day), shared: true, :amount.lt => 0).map(&:amount).sum.to_s
end