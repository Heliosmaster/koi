class Transaction
  include DataMapper::Resource
  property :id, Serial
  property :amount, Float, required: true
  property :date, Date, required: true
  property :target, String
  property :reason, String
  property :shared, Boolean, default: true

  belongs_to :user

  default_scope(:default).update(:order => [:date.asc])

  def self.create_from_params(params, user)
    t = new
    t.amount = params["amount"].to_f
    t.date = Date.parse(params["date"])
    t.user = user
    t.reason = params["reason"]
    t.target = params["target"]
    t.shared = params["shared"]
    throw t.errors unless t.save
  end

  def month
    self.date.month
  end

  def year
    self.date.year
  end

  def income?
    self.amount >= 0
  end

  def update_from_params(params)
    self.amount = params["amount"].to_f
    self.date = Date.parse(params["date"])
    self.reason = params["reason"]
    self.target = params["target"]
    self.shared = params["shared"]
    throw self.errors unless self.save
  end

  def self.create_from_csv(csv,user,default_shared)
    CSV.foreach(csv) do |row|
      t = new
      t.date = row[2]
      t.amount = (row[3] == "C" ? row[4].to_f : -row[4].to_f)
      t.reason = row[10]
      t.target = row[6]
      t.user = user
      t.shared = default_shared
      throw t.errors unless t.save
    end
  end

  def different_month?(transaction)
    self.date.month != transaction.date.month
  end

end



class User
  include DataMapper::Resource
  property :id, Serial
  property :name, String, required: true, unique: true

  has n, :transactions

  def total_expenses
    transactions(:amount.gte => 0).map(&:amount).sum.round(2)
  end

  def self.average_expenses
    (User.all.map(&:total_expenses).sum/User.count).round(2)
  end

  def transactions_by_year_month
    t = self.transactions.group_by(&:year)
    grouped_transactions = {}
    t.each do |year,transactions_in_year|
      grouped_transactions[year] = transactions_in_year.group_by(&:month)
    end
    grouped_transactions
  end
end
