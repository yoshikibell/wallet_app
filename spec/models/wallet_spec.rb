# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Wallet, type: :model do
  let(:user) { User.create!(name: Faker::Name.name, email: Faker::Internet.email) }
  let(:wallet) { user.wallet }

  describe 'default values' do
    it 'has a default balance of 0.0' do
      new_user = User.create!(name: Faker::Name.name, email: Faker::Internet.email)
      new_wallet = new_user.wallet
      expect(new_wallet.balance).to eq(0.0)
    end
  end
end
