# frozen_string_literal: true

class AddStatusToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :status, :integer,
               default: 0,
               null: false,
               comment: 'Transaction status: 0=pending, 1=completed, 2=failed. Tracks transaction lifecycle for audit trails and error handling.'
  end
end
