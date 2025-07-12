# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransactionService, type: :service do
  let(:user1) { User.create!(name: 'Alice', email: 'alice@example.com') }
  let(:user2) { User.create!(name: 'Bob', email: 'bob@example.com') }
  let(:wallet1) { user1.wallet }
  let(:wallet2) { user2.wallet }

  before do
    wallet1.update!(balance: 1000.0)
    wallet2.update!(balance: 500.0)
  end

  describe '.create_deposit!' do
    context 'with valid parameters' do
      it 'creates a successful deposit transaction' do
        expect {
          described_class.create_deposit!(wallet: wallet1, amount: 100.0)
        }.to change { wallet1.reload.balance }.by(100.0)
          .and change { Transaction.count }.by(1)
      end

      it 'creates transaction with correct attributes' do
        transaction = described_class.create_deposit!(wallet: wallet1, amount: 100.0)

        expect(transaction).to have_attributes(
          wallet: wallet1,
          amount: 100.0,
          transaction_type: 'deposit',
          status: 'completed',
          initiator: wallet1,
          receiver: nil
        )
      end

      it 'handles decimal amounts correctly' do
        transaction = described_class.create_deposit!(wallet: wallet1, amount: 99.99)

        expect(transaction.amount).to eq(99.99)
        expect(wallet1.reload.balance).to eq(1099.99)
      end
    end

    context 'with invalid parameters' do
      it 'raises InvalidTransactionError for negative amount' do
        expect {
          described_class.create_deposit!(wallet: wallet1, amount: -100.0)
        }.to raise_error(TransactionService::InvalidTransactionError)
      end

      it 'raises InvalidTransactionError for zero amount' do
        expect {
          described_class.create_deposit!(wallet: wallet1, amount: 0)
        }.to raise_error(TransactionService::InvalidTransactionError)
      end

      it 'does not change wallet balance on validation error' do
        expect {
          begin
            described_class.create_deposit!(wallet: wallet1, amount: -100.0)
          rescue TransactionService::InvalidTransactionError
            # NOTE: Expected error, continue with test
          end
        }.not_to change { wallet1.reload.balance }
      end
    end
  end

  describe '.create_withdrawal!' do
    context 'with valid parameters' do
      it 'creates a successful withdrawal transaction' do
        expect {
          described_class.create_withdrawal!(wallet: wallet1, amount: 100.0)
        }.to change { wallet1.reload.balance }.by(-100.0)
          .and change { Transaction.count }.by(1)
      end

      it 'creates transaction with correct attributes' do
        transaction = described_class.create_withdrawal!(wallet: wallet1, amount: 100.0)

        expect(transaction).to have_attributes(
          wallet: wallet1,
          amount: 100.0,
          transaction_type: 'withdrawal',
          status: 'completed',
          initiator: wallet1,
          receiver: nil
        )
      end

      it 'allows withdrawal of entire balance' do
        transaction = described_class.create_withdrawal!(wallet: wallet1, amount: 1000.0)

        expect(wallet1.reload.balance).to eq(0.0)
        expect(transaction.status).to eq('completed')
      end
    end

    context 'with insufficient funds' do
      it 'raises InsufficientFundsError' do
        expect {
          described_class.create_withdrawal!(wallet: wallet1, amount: 1500.0)
        }.to raise_error(TransactionService::InsufficientFundsError, /Insufficient balance/)
      end

      it 'does not change wallet balance on insufficient funds' do
        expect {
          begin
            described_class.create_withdrawal!(wallet: wallet1, amount: 1500.0)
          rescue TransactionService::InsufficientFundsError
            # Expected error, continue with test
          end
        }.not_to change { wallet1.reload.balance }
      end

      it 'does not create transaction on insufficient funds' do
        expect {
          begin
            described_class.create_withdrawal!(wallet: wallet1, amount: 1500.0)
          rescue TransactionService::InsufficientFundsError
            # Expected error, continue with test
          end
        }.not_to change { Transaction.count }
      end
    end

    context 'with invalid parameters' do
      it 'raises InvalidTransactionError for negative amount' do
        expect {
          described_class.create_withdrawal!(wallet: wallet1, amount: -100.0)
        }.to raise_error(TransactionService::InvalidTransactionError)
      end

      it 'raises InvalidTransactionError for zero amount' do
        expect {
          described_class.create_withdrawal!(wallet: wallet1, amount: 0)
        }.to raise_error(TransactionService::InvalidTransactionError)
      end
    end
  end

  describe '.create_transfer!' do
    context 'with valid parameters' do
      it 'creates a successful transfer transaction' do
        expect {
          described_class.create_transfer!(
            from_wallet: wallet1,
            to_wallet: wallet2,
            amount: 200.0
          )
        }.to change { wallet1.reload.balance }.by(-200.0)
          .and change { wallet2.reload.balance }.by(200.0)
          .and change { Transaction.count }.by(1)
      end

      it 'creates transaction with correct attributes' do
        transaction = described_class.create_transfer!(
          from_wallet: wallet1,
          to_wallet: wallet2,
          amount: 200.0
        )

        expect(transaction).to have_attributes(
          wallet: wallet1,
          amount: 200.0,
          transaction_type: 'transfer',
          status: 'completed',
          initiator: wallet1,
          receiver: wallet2
        )
      end

      it 'handles transfers between wallets with different IDs correctly' do
        # Test wallet locking order (lower ID first)
        transaction = described_class.create_transfer!(
          from_wallet: wallet2,
          to_wallet: wallet1,
          amount: 100.0
        )

        expect(wallet2.reload.balance).to eq(400.0)
        expect(wallet1.reload.balance).to eq(1100.0)
        expect(transaction.initiator).to eq(wallet2)
        expect(transaction.receiver).to eq(wallet1)
      end
    end

    context 'with insufficient funds' do
      it 'raises InsufficientFundsError' do
        expect {
          described_class.create_transfer!(
            from_wallet: wallet1,
            to_wallet: wallet2,
            amount: 1500.0
          )
        }.to raise_error(TransactionService::InsufficientFundsError, /Insufficient balance/)
      end

      it 'does not change any wallet balance on insufficient funds' do
        expect {
          begin
            described_class.create_transfer!(
              from_wallet: wallet1,
              to_wallet: wallet2,
              amount: 1500.0
            )
          rescue TransactionService::InsufficientFundsError
            # Expected error, continue with test
          end
        }.not_to change { [ wallet1.reload.balance, wallet2.reload.balance ] }
      end

      it 'does not create transaction on insufficient funds' do
        expect {
          begin
            described_class.create_transfer!(
              from_wallet: wallet1,
              to_wallet: wallet2,
              amount: 1500.0
            )
          rescue TransactionService::InsufficientFundsError
            # Expected error, continue with test
          end
        }.not_to change { Transaction.count }
      end
    end

    context 'with invalid parameters' do
      it 'raises InvalidTransactionError for negative amount' do
        expect {
          described_class.create_transfer!(
            from_wallet: wallet1,
            to_wallet: wallet2,
            amount: -100.0
          )
        }.to raise_error(TransactionService::InvalidTransactionError)
      end

      it 'raises InvalidTransactionError for zero amount' do
        expect {
          described_class.create_transfer!(
            from_wallet: wallet1,
            to_wallet: wallet2,
            amount: 0
          )
        }.to raise_error(TransactionService::InvalidTransactionError)
      end
    end
  end

  describe 'concurrency and locking' do
    it 'handles concurrent deposits safely' do
      threads = []

      10.times do
        threads << Thread.new do
          described_class.create_deposit!(wallet: wallet1, amount: 10.0)
        end
      end

      threads.each(&:join)

      expect(wallet1.reload.balance).to eq(1100.0) # 1000 + (10 * 10)
      expect(Transaction.where(wallet: wallet1, transaction_type: :deposit).count).to eq(10)
    end

    it 'handles concurrent withdrawals safely' do
      threads = []

      5.times do
        threads << Thread.new do
          described_class.create_withdrawal!(wallet: wallet1, amount: 100.0)
        end
      end

      threads.each(&:join)

      expect(wallet1.reload.balance).to eq(500.0) # 1000 - (5 * 100)
      expect(Transaction.where(wallet: wallet1, transaction_type: :withdrawal).count).to eq(5)
    end

    it 'prevents deadlocks in bidirectional transfers' do
      threads = []

      # Thread 1: wallet1 -> wallet2
      threads << Thread.new do
        described_class.create_transfer!(
          from_wallet: wallet1,
          to_wallet: wallet2,
          amount: 100.0
        )
      end

      # Thread 2: wallet2 -> wallet1 (reverse direction)
      threads << Thread.new do
        described_class.create_transfer!(
          from_wallet: wallet2,
          to_wallet: wallet1,
          amount: 50.0
        )
      end

      threads.each(&:join)

      expect(Transaction.where(transaction_type: :transfer).count).to eq(2)
    end
  end
end
