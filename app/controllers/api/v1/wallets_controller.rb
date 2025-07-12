# frozen_string_literal: true

module Api
  module V1
    class WalletsController < BaseController
      before_action :set_wallet

      rescue_from StandardError, with: :handle_generic_error
      rescue_from TransactionService::InsufficientFundsError, with: :handle_insufficient_funds
      rescue_from TransactionService::InvalidTransactionError, with: :handle_invalid_transaction
      rescue_from ActionController::ParameterMissing, with: :handle_missing_parameter

      # POST /api/v1/wallets/deposit
      def deposit
        amount = amount_param

        transaction = TransactionService.create_deposit!(
          wallet: @wallet,
          amount: amount
        )

        render_transaction_success("Deposit successful", transaction)
      end

      # POST /api/v1/wallets/withdraw
      def withdraw
        amount = amount_param

        transaction = TransactionService.create_withdrawal!(
          wallet: @wallet,
          amount: amount
        )

        render_transaction_success("Withdrawal successful", transaction)
      end

      # POST /api/v1/wallets/transfer
      def transfer
        receiver_id = receiver_id_param
        amount = amount_param

        receiver = User.find_by(id: receiver_id)&.wallet
        raise TransactionService::InvalidTransactionError.new("Receiver not found") unless receiver

        transaction = TransactionService.create_transfer!(
          from_wallet: @wallet,
          to_wallet: receiver,
          amount: amount
        )

        render_transaction_success("Transfer successful", transaction)
      end

      # GET /api/v1/wallets/balance
      def balance
        render json: {
          balance: @wallet.balance,
          user: {
            id: current_user.id,
            name: current_user.name,
            email: current_user.email
          }
        }
      end

      # GET /api/v1/wallets/transactions
      def transactions
        @transactions = @wallet.transactions.includes(:initiator, :receiver)
                               .order(created_at: :desc)

        render json: @transactions.as_json(
          except: [ :created_at, :updated_at ],
          include: {
            initiator: { only: [ :id ], include: { user: { only: [ :name, :email ] } } },
            receiver: { only: [ :id ], include: { user: { only: [ :name, :email ] } } }
          }
        )
      end

      private

      def set_wallet
        @wallet = current_user.wallet
      end

      def amount_param
        params.require(:amount).to_d
      end

      def receiver_id_param
        params.require(:receiver_id)
      end

      def render_transaction_success(message, transaction)
        render json: {
          message: message,
          balance: @wallet.reload.balance,
          transaction: transaction.as_json(except: [ :created_at, :updated_at ])
        }
      end

      def handle_insufficient_funds(error)
        log_error(error, "Insufficient funds for wallet operation")
        render json: { error: error.message }, status: :unprocessable_entity
      end

      def handle_invalid_transaction(error)
        log_error(error, "Invalid transaction attempted")
        render json: { error: error.message }, status: :unprocessable_entity
      end

      def handle_missing_parameter(error)
        log_error(error, "Missing required parameter")

        render json: { error: "Missing parameter" }, status: :bad_request
      end

      def handle_generic_error(error)
        log_error(error, "Unexpected error occurred")
        render json: { error: "An unexpected error occurred" }, status: :internal_server_error
      end

      def log_error(error, message = nil)
        Rails.logger.error(error.backtrace.join("\n")) if error.backtrace

        # SUGGESTION: send errors to external monitoring services here (i.e. Sentry, New Relic, Bugsnag)
      end
    end
  end
end
