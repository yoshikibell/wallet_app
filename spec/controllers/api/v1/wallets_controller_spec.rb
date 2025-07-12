# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::WalletsController, type: :controller do
  let(:user) { User.create!(name: Faker::Name.name, email: Faker::Internet.email) }
  let(:other_user) { User.create!(name: Faker::Name.name, email: Faker::Internet.email) }
  let(:wallet) { user.wallet }
  let(:other_wallet) { other_user.wallet }

  let(:valid_token) do
    JWT.encode(
      { user_id: user.id, email: user.email },
      Rails.application.secret_key_base,
      'HS256'
    )
  end

  let(:invalid_token) { 'invalid.token.here' }

  before do
    wallet.update!(balance: 1000.0)
    other_wallet.update!(balance: 500.0)
    allow(Rails.logger).to receive(:error)
  end

  describe 'authentication' do
    it 'requires valid JWT token' do
      request.headers['Authorization'] = "Bearer #{invalid_token}"
      post :deposit, params: { amount: 100.0 }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to eq('Invalid token')
    end

    it 'requires Authorization header' do
      post :deposit, params: { amount: 100.0 }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to eq('Invalid token')
    end

    it 'allows requests with valid token' do
      request.headers['Authorization'] = "Bearer #{valid_token}"
      post :deposit, params: { amount: 100.0 }

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #deposit' do
    before do
      request.headers['Authorization'] = "Bearer #{valid_token}"
    end

    context 'with valid parameters' do
      it 'creates a deposit transaction' do
        expect {
          post :deposit, params: { amount: 100.0 }
        }.to change { wallet.reload.balance }.by(100.0)
          .and change { Transaction.count }.by(1)

        expect(response).to have_http_status(:ok)
      end

      it 'returns success response with transaction details' do
        post :deposit, params: { amount: 100.0 }

        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'message' => 'Deposit successful',
          'balance' => '1100.0',
          'transaction' => anything
        )
        expect(json_response['transaction']).to include(
          'amount' => '100.0',
          'transaction_type' => 'deposit',
          'status' => 'completed'
        )
      end

      it 'handles decimal amounts' do
        post :deposit, params: { amount: 99.99 }

        expect(wallet.reload.balance).to eq(1099.99)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid parameters' do
      it 'returns error for missing amount' do
        post :deposit

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Missing parameter')
        expect(Rails.logger).to have_received(:error).with(anything)
      end

      it 'returns error for negative amount' do
        post :deposit, params: { amount: -100.0 }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to include('must be greater than 0')
        expect(Rails.logger).to have_received(:error).with(anything)
      end

      it 'returns error for zero amount' do
        post :deposit, params: { amount: 0 }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to include('must be greater than 0')
        expect(Rails.logger).to have_received(:error).with(anything)
      end
    end
  end

  describe 'POST #withdraw' do
    before do
      request.headers['Authorization'] = "Bearer #{valid_token}"
    end

    context 'with valid parameters' do
      it 'creates a withdrawal transaction' do
        expect {
          post :withdraw, params: { amount: 100.0 }
        }.to change { wallet.reload.balance }.by(-100.0)
          .and change { Transaction.count }.by(1)

        expect(response).to have_http_status(:ok)
      end

      it 'returns success response with transaction details' do
        post :withdraw, params: { amount: 100.0 }

        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'message' => 'Withdrawal successful',
          'balance' => '900.0',
          'transaction' => anything
        )
        expect(json_response['transaction']).to include(
          'amount' => '100.0',
          'transaction_type' => 'withdrawal',
          'status' => 'completed'
        )
      end

      it 'allows withdrawal of entire balance' do
        post :withdraw, params: { amount: 1000.0 }

        expect(wallet.reload.balance).to eq(0.0)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with insufficient funds' do
      it 'returns error for amount exceeding balance' do
        post :withdraw, params: { amount: 1500.0 }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to include('Insufficient balance')
        expect(Rails.logger).to have_received(:error).with(anything)
      end

      it 'does not change wallet balance on insufficient funds' do
        expect {
          post :withdraw, params: { amount: 1500.0 }
        }.not_to change { wallet.reload.balance }
      end
    end

    context 'with invalid parameters' do
      it 'returns error for missing amount' do
        post :withdraw

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Missing parameter')
        expect(Rails.logger).to have_received(:error).with(anything)
      end

      it 'returns error for negative amount' do
        post :withdraw, params: { amount: -100.0 }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to include('must be greater than 0')
        expect(Rails.logger).to have_received(:error).with(anything)
      end
    end
  end

  describe 'POST #transfer' do
    before do
      request.headers['Authorization'] = "Bearer #{valid_token}"
    end

    context 'with valid parameters' do
      it 'creates a transfer transaction' do
        expect {
          post :transfer, params: { receiver_id: other_user.id, amount: 200.0 }
        }.to change { wallet.reload.balance }.by(-200.0)
          .and change { other_wallet.reload.balance }.by(200.0)
          .and change { Transaction.count }.by(1)

        expect(response).to have_http_status(:ok)
      end

      it 'returns success response with transaction details' do
        post :transfer, params: { receiver_id: other_user.id, amount: 200.0 }

        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'message' => 'Transfer successful',
          'balance' => '800.0',
          'transaction' => anything
        )
        expect(json_response['transaction']).to include(
          'amount' => '200.0',
          'transaction_type' => 'transfer',
          'status' => 'completed'
        )
      end
    end

    context 'with invalid receiver' do
      it 'returns error for non-existent receiver' do
        post :transfer, params: { receiver_id: 99999, amount: 200.0 }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Receiver not found')
        expect(Rails.logger).to have_received(:error).with(anything)
      end

      it 'does not change wallet balances for invalid receiver' do
        expect {
          post :transfer, params: { receiver_id: 99999, amount: 200.0 }
        }.not_to change { [ wallet.reload.balance, other_wallet.reload.balance ] }
      end
    end

    context 'with insufficient funds' do
      it 'returns error for amount exceeding balance' do
        post :transfer, params: { receiver_id: other_user.id, amount: 1500.0 }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to include('Insufficient balance')
        expect(Rails.logger).to have_received(:error).with(anything)
      end

      it 'does not change wallet balances on insufficient funds' do
        expect {
          post :transfer, params: { receiver_id: other_user.id, amount: 1500.0 }
        }.not_to change { [ wallet.reload.balance, other_wallet.reload.balance ] }
      end
    end

    context 'with invalid parameters' do
      it 'returns error for missing receiver_id' do
        post :transfer, params: { amount: 200.0 }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Missing parameter')
        expect(Rails.logger).to have_received(:error).with(anything)
      end

      it 'returns error for missing amount' do
        post :transfer, params: { receiver_id: other_user.id }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Missing parameter')
        expect(Rails.logger).to have_received(:error).with(anything)
      end

      it 'returns error for negative amount' do
        post :transfer, params: { receiver_id: other_user.id, amount: -100.0 }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to include('must be greater than 0')
        expect(Rails.logger).to have_received(:error).with(anything)
      end
    end
  end

  describe 'GET #balance' do
    before do
      request.headers['Authorization'] = "Bearer #{valid_token}"
    end

    it 'returns current wallet balance with user details' do
      get :balance

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        'balance' => '1000.0',
        'user' => {
          'id' => user.id,
          'name' => user.name,
          'email' => user.email
        }
      )
    end
  end

  describe 'GET #transactions' do
    before do
      request.headers['Authorization'] = "Bearer #{valid_token}"
    end

    it 'returns list of transactions' do
      TransactionService.create_deposit!(wallet: wallet, amount: 100.0)
      TransactionService.create_withdrawal!(wallet: wallet, amount: 50.0)
      TransactionService.create_transfer!(from_wallet: wallet, to_wallet: other_wallet, amount: 25.0)

      get :transactions

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(3)
      expect(json_response.first).to include(
        'transaction_type',
        'amount',
        'status'
      )
    end
  end
end
