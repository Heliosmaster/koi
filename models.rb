class Transaction
  include DataMapper::Resource
  property :id, Serial
  property :amount, Decimal, precision: 8, scale: 2, required: true
  property :date, Date, required: true
  property :target, Text, lazy: false
  property :reason, Text, lazy: false, required: true
  property :shared, Boolean, default: false
  validates_with_method :check_fields

  belongs_to :user

  default_scope(:default).update(:order => [:date.asc])

  def check_fields
    if Transaction.all(amount: self.amount, date: self.date, reason: self.reason).empty?
      return true
    else
      return false, "This combination is not unique"
    end
  end

  def self.create_from_params(params, user)
    t = new
    t.amount = params["amount"].to_f
    t.date = Date.parse(params["date"])
    t.user = user
    t.reason = params["reason"]
    t.target = params["target"]
    t.shared = params["shared"]
    t.errors unless t.save
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
    self.errors unless self.save
  end



  def self.create_from_rabobank_csv(csv,user,default_shared)
    @last_import_date = user.last_import_date
    @last_import_id = user.last_import_id
    errors = []

    CSV.foreach(csv) do |row|
      @date = Date.parse(row[2])
      t = new
      t.date = @date
      t.amount = (row[3] == "C" ? row[4].to_f : -row[4].to_f)
      t.target = (row[5] + " " + row[6]).rstrip
      t.reason = (row[10] + " " + row[11] + " " + row[12] + " " + row[13] + " " + row[14] + " " + row[15]).rstrip
      t.user_id = user.id
      t.shared = default_shared
      if !@last_import_date || @last_import_date < @date
        user.last_import_date = @date
        @last_import_date = @date
      end
      if t.save
        if !@last_import_id || @last_import_id < t.id
          user.last_import_id = t.id
        end
      else
        errors << t.errors
      end
    end
    errors
  end

  def self.create_from_koi_csv(csv,user)
    @last_import_date = user.last_import_date
    @last_import_id = user.last_import_id
    errors = []

    CSV.foreach(csv, headers: true) do |row|
      @date = Date.parse(row['Date'])
      t = new
      t.date = @date
      t.amount = row['amount']
      t.target = row['target']
      t.reason = row['reason']
      t.user_id = user.id
      t.shared = row['shared']
      if !@last_import_date || @last_import_date < @date
        user.last_import_date = @date
        @last_import_date = @date
      end
      if t.save
        if !@last_import_id || @last_import_id < t.id
          user.last_import_id = t.id
        end
      else
        errors << t.errors
      end
    end
    errors
  end

  def to_csv_row
    "#{self.date.strftime("%d/%m/%Y")},#{self.amount},#{self.target},#{self.reason},#{self.shared}"
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
  property :last_import_date, Date
  property :last_import_id, Integer
  property :total_shared_expenses, Decimal, precision: 8, scale: 2, default: 0
  property :difference, Decimal, precision: 8, scale: 2, default: 0
  property :color, String, unique: true
  has n, :transactions

  def update_values
    total_expenses = transactions(shared: true, :amount.lte => 0).map(&:amount).sum.abs
    self.total_shared_expenses = total_expenses
    self.difference = (total_expenses-User.average_expenses)
    self.save!
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

  def daily_increments(transactions)
    start_day = transactions.first.date
    end_day = transactions.last.date
    final_hash = {}
    (start_day+1..end_day).each do |day|
      final_hash[day] = transactions.select{|t| t.date == day}.map(&:amount).sum
    end
    final_hash
  end

  def daily_balance(transactions)
    sum = 0
    increments = self.daily_increments(transactions)
    Hash[increments.keys.zip(increments.values.map { |x| sum += x})]
  end

end

class BigDecimal
  old_to_s = instance_method :to_s

  define_method :to_s do |param='F'|
    old_to_s.bind(self).(param)
  end
end
