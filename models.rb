class Transaction
  include DataMapper::Resource
  property :id, Serial
  property :amount, Decimal, precision: 8, scale: 2, required: true, unique_index: :date_amount_target
  property :date, Date, required: true, unique_index: :date_amount_target
  property :target, String, required: true, unique_index: :date_amount_target
  property :reason, String
  property :shared, Boolean, default: true

  validates_uniqueness_of :amount, :scope => [:date, :target]

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
    @user = user
    @last_import = @user.last_import

    CSV.foreach(csv) do |row|
      @date = Date.parse(row[2])
      t = new
      t.date = @date
      t.amount = (row[3] == "C" ? row[4].to_f : -row[4].to_f)
      if row[6].empty?
        t.target = row[10]
        t.reason = ""
      else
        t.target = row[6]
        t.reason = row[10]
      end
      t.user_id = @user.id
      t.shared = default_shared
      if !@last_import || @last_import < @date
        @user.last_import = @date
        @last_import = @date
      end
      throw t.errors unless t.save
    end
  end

  def to_csv_row
    "#{self.date.strftime("%d/%m/%Y")},#{self.amount},#{self.target},#{self.reason},#{self.shared}"
  end

  def different_month?(transaction)
    self.date.month != transaction.date.month
  end

  def self.all_shared_into_hash
    t = Transaction.all(shared: true).group_by(&:year)
    grouped_transactions = {}
    t.each do |year,transactions_in_year|
      grouped_transactions[year] = transactions_in_year.group_by(&:month)
    end
    grouped_transactions
  end

end


class User
  include DataMapper::Resource
  property :id, Serial
  property :name, String, required: true, unique: true
  property :last_import, Date
  property :total_shared_expenses, Decimal, precision: 8, scale: 2, default: 0
  property :difference, Decimal, precision: 8, scale: 2, default: 0

  has n, :transactions

  def update_total_shared_expenses
    self.total_shared_expenses = transactions(shared: true, :amount.lte => 0).map(&:amount).sum.abs.round(2)
    self.save!
  end

  def update_differences
    self.difference = (total_shared_expenses-User.average_expenses)
    self.save!
  end

  def update_values
    self.update_total_shared_expenses
    self.update_differences
  end

  def self.average_expenses
    (User.all.map(&:total_shared_expenses).sum/User.count)
  end

  def transactions_by_year_month
    t = self.transactions.group_by(&:year)
    grouped_transactions = {}
    t.each do |year,transactions_in_year|
      grouped_transactions[year] = transactions_in_year.group_by(&:month)
    end
    grouped_transactions
  end

  def export_to_csv
    "Date,amount,target,reason,shared" + "\n" +
    self.transactions.map(&:to_csv_row).join("\n") + "\n"
  end

  def self.expenses_and_differences
    stats = {}
    User.all.each do |user|
      stats[user.id] = {}
      stats[user.id][:expenses] = user.total_shared_expenses
      stats[user.id][:difference] = user.difference
    end
    stats
  end

end

class BigDecimal
  old_to_s = instance_method :to_s

  define_method :to_s do |param='F'|
    old_to_s.bind(self).(param)
  end
end
