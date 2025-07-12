# frozen_string_literal: true

module Api
  module V1
    class WalletsController < BaseController
      before_action :set_wallet

      rescue_from TransactionService::InsufficientFundsError, with: :handle_insufficient_funds
      rescue_from TransactionService::InvalidTransactionError, with: :handle_invalid_transaction

      # POST /api/v1/wallets/deposit
      def deposit
        transaction = TransactionService.create_deposit!(
          wallet: @wallet,
          amount: amount_param
        )

        render_transaction_success("Deposit successful", transaction)
      end

      # POST /api/v1/wallets/withdraw
      def withdraw
        transaction = TransactionService.create_withdrawal!(
          wallet: @wallet,
          amount: amount_param
        )

        render_transaction_success("Withdrawal successful", transaction)
      end

      # POST /api/v1/wallets/transfer
      def transfer
        receiver = User.find_by(id: receiver_id_param)&.wallet

        unless receiver
          return render json: { error: "Receiver not found" }, status: :not_found
        end

        transaction = TransactionService.create_transfer!(
          from_wallet: @wallet,
          to_wallet: receiver,
          amount: amount_param
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
      rescue ActionController::ParameterMissing
        render json: { error: "Amount is required" }, status: :bad_request
        nil
      end

      def receiver_id_param
        params.require(:receiver_id)
      rescue ActionController::ParameterMissing
        render json: { error: "Receiver ID is required" }, status: :bad_request
        nil
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

      def log_error(error, message = nil)
        Rails.logger.error(error.backtrace.join("\n")) if error.backtrace

        # SUGGESTION: send errors to external monitoring services here (i.e. Sentry, New Relic, Bugsnag)
      end
    end
  end
end
