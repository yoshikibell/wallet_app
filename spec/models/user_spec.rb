# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'callbacks' do
    it 'creates a wallet after user creation' do
      user = User.new(name: Faker::Name.name, email: Faker::Internet.email)
      expect(user.wallet).to be_nil

      user.save!
      user.reload

      expect(user.wallet).to be_present
      expect(user.wallet.balance).to eq(0.0)
    end
  end
end
