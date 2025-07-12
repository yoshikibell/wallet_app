# frozen_string_literal: true

class TransactionService
  class InsufficientFundsError < StandardError; end
  class TransactionProcessingError < StandardError; end
  class InvalidTransactionError < StandardError; end

  def self.create_deposit!(wallet:, amount:)
    ActiveRecord::Base.transaction do
      locked_wallet = wallet.lock!

      transaction = Transaction.create!(
        wallet: locked_wallet,
        amount: amount,
        transaction_type: :deposit,
        status: :pending
      )

      locked_wallet.increment!(:balance, amount)
      transaction.update!(status: :completed)
      transaction
    end
  rescue ActiveRecord::RecordInvalid => e
    raise InvalidTransactionError, e.record.errors.full_messages.join(", ")
  end

  def self.create_withdrawal!(wallet:, amount:)
    ActiveRecord::Base.transaction do
      locked_wallet = wallet.lock!

      if locked_wallet.balance < amount
        raise InsufficientFundsError, "Insufficient balance. Available: #{locked_wallet.balance}, Required: #{amount}"
      end

      transaction = Transaction.create!(
        wallet: locked_wallet,
        amount: amount,
        transaction_type: :withdrawal,
        status: :pending
      )

      locked_wallet.decrement!(:balance, amount)
      transaction.update!(status: :completed)
      transaction
    end
  rescue ActiveRecord::RecordInvalid => e
    raise InvalidTransactionError, e.record.errors.full_messages.join(", ")
  rescue InsufficientFundsError
    raise
  end

  def self.create_transfer!(from_wallet:, to_wallet:, amount:)
    ActiveRecord::Base.transaction do
      # NOTE: for when two users happen to transfer to each other at the same time, we need to lock the wallets in a consistent order
      if from_wallet.id < to_wallet.id
        locked_from = from_wallet.lock!
        locked_to = to_wallet.lock!
      else
        locked_to = to_wallet.lock!
        locked_from = from_wallet.lock!
      end

      if locked_from.balance < amount
        raise InsufficientFundsError, "Insufficient balance. Available: #{locked_from.balance}, Required: #{amount}"
      end

      transaction = Transaction.create!(
        wallet: locked_from,
        initiator: locked_from,
        receiver: locked_to,
        amount: amount,
        transaction_type: :transfer,
        status: :pending
      )

      locked_from.decrement!(:balance, amount)
      locked_to.increment!(:balance, amount)
      transaction.update!(status: :completed)
      transaction
    end
  rescue ActiveRecord::RecordInvalid => e
    raise InvalidTransactionError, e.record.errors.full_messages.join(", ")
  rescue InsufficientFundsError
    raise
  end
end
