class Transaction
  include DataMapper::Resource
  property :id, Serial
  property :amount, Float, required: true
  property :date, Date, required: true
  property :target, String
  property :reason, String

  belongs_to :user

  def self.create_from_params(params,user)
    t = new
    t.amount = params["amount"].to_f
    t.date = Date.parse(params["date"])
    t.user = user
    t.reason = params["reason"]
    t.target = params["target"]
    throw t.errors unless t.save
  end
end

class User
  include DataMapper::Resource
  property :id, Serial
  property :name, String, required: true, unique: true

  has n, :transactions
end

