# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

users_data = [
  {
    name: "Richard Hendricks",
    email: "richard@piedpiper.com"
  },
  {
    name: "Erlich Bachman",
    email: "erlich@aviato.com"
  }
]

puts "\n=== Test Users ==="

users = users_data.map do |user_data|
  User.find_or_create_by(email: user_data[:email]) do |u|
    u.name = user_data[:name]
  end.reload
end

users.each do |user|
  token = JWT.encode(
    {
      user_id: user.id,
      exp: 1.year.from_now.to_i
    },
    Rails.application.secret_key_base,
    'HS256'
  )

  puts "\n#{user.name} (ID: #{user.id})"
  puts "Balance: $#{user.wallet.balance}"
  puts "Token: #{token}"
end

richard = users[0]
erlich = users[1]

puts "\n=== API Testing Instructions ==="
puts "1. Deposit to Richard's wallet:"
puts "   POST /api/v1/wallets/deposit"
puts "   Headers: { Authorization: Bearer <Richard's Token> }"
puts "   Body: { \"amount\": 1000 }"

puts "\n2. Transfer from Richard to Erlich:"
puts "   POST /api/v1/wallets/transfer"
puts "   Headers: { Authorization: Bearer <Richard's Token> }"
puts "   Body: { \"amount\": 500, \"receiver_id\": #{erlich.id} }"

puts "\n3. Check Richard's balance:"
puts "   GET /api/v1/wallets/balance"
puts "   Headers: { Authorization: Bearer <Richard's Token> }"

puts "\n4. Check Richard's transactions:"
puts "   GET /api/v1/wallets/transactions"
puts "   Headers: { Authorization: Bearer <Richard's Token> }"

puts "\n5. Withdraw from Erlich's wallet:"
puts "   POST /api/v1/wallets/withdraw"
puts "   Headers: { Authorization: Bearer <Erlich's Token> }"
puts "   Body: { \"amount\": 100 }"
