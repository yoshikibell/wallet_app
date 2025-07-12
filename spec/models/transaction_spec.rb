# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'an invalid transaction' do |error_message|
  it 'is invalid with the correct error message' do
    expect(transaction).to be_invalid
    expect(transaction.errors[:base]).to include(error_message)
  end
end

RSpec.describe Transaction do
  describe 'validations' do
    subject(:transaction) { described_class.new(attributes) }

    let(:user1) { User.create!(name: Faker::Name.name, email: Faker::Internet.email) }
    let(:user2) { User.create!(name: Faker::Name.name, email: Faker::Internet.email) }
    let(:wallet1) { user1.wallet }
    let(:wallet2) { user2.wallet }

    context 'when transaction type is transfer' do
      context 'when initiator is missing' do
        let(:attributes) do
          {
            wallet: wallet1,
            amount: 100,
            transaction_type: :transfer,
            receiver: wallet2
          }
        end

        it_behaves_like 'an invalid transaction', 'Both initiator and receiver must be present for transfers'
      end

      context 'when receiver is missing' do
        let(:attributes) do
          {
            wallet: wallet1,
            amount: 100,
            transaction_type: :transfer,
            initiator: wallet1
          }
        end

        it_behaves_like 'an invalid transaction', 'Both initiator and receiver must be present for transfers'
      end

      context 'when initiator and receiver are the same wallet' do
        let(:attributes) do
          {
            wallet: wallet1,
            amount: 100,
            transaction_type: :transfer,
            initiator: wallet1,
            receiver: wallet1
          }
        end

        it_behaves_like 'an invalid transaction', 'Initiator and receiver must be different'
      end

      context 'when initiator and receiver are different wallets' do
        let(:attributes) do
          {
            wallet: wallet1,
            amount: 100,
            transaction_type: :transfer,
            initiator: wallet1,
            receiver: wallet2
          }
        end

        it { is_expected.to be_valid }
      end
    end

    context "when transaction type is deposit" do
      let(:attributes) do
        {
          wallet: wallet1,
          amount: 100,
          transaction_type: :deposit
        }
      end

      it { is_expected.to be_valid }
    end

    context "when transaction type is withdrawal" do
      let(:attributes) do
        {
          wallet: wallet1,
          amount: 100,
          transaction_type: :withdrawal
        }
      end

      it { is_expected.to be_valid }
    end
  end
end
