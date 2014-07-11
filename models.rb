class Transaction
  include DataMapper::Resource
  property :id, Serial
  property :amount, Float, required: true
  property :date, Date, required: true
  property :target, String
  property :reason_text, String

  belongs_to :user

end

class User
  include DataMapper::Resource
  property :id, Serial
  property :name, String, required: true, unique: true

  has n, :transactions
end

