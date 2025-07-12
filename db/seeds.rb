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
  },
  {
    name: "Jian Yang",
    email: "jian.yang@newpiedpiper.com"
  }
]

puts "=== API Test Users ==="

users_data.each do |user_data|
  user = User.find_or_create_by(email: user_data[:email]) do |u|
    u.name = user_data[:name]
  end.reload

  token = JWT.encode(
    {
      user_id: user.id,
      email: user.email,
      exp: 1.year.from_now.to_i
    },
    Rails.application.secret_key_base,
    'HS256'
  )

  puts "Name: #{user.name}"
  puts "Email: #{user.email}"
  puts "ID: #{user.id}"
  puts "Wallet Balance: $#{user.wallet.balance}"
  puts "JWT Token: #{token}"
  puts "------------------------"
end

puts "Now you can test:"
puts "1. Deposits to each user's wallet"
puts "2. Withdrawals from each user's wallet"
puts "3. Transfers between users (e.g., Richard → Erlich → Jian Yang)"
puts "4. Balance checks"
puts "5. Transaction history"
