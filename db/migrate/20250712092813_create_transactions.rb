# frozen_string_literal: true

class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :wallet, null: false, foreign_key: true
      t.references :initiator, null: true, foreign_key: { to_table: :wallets }, index: true
      t.references :receiver, null: true, foreign_key: { to_table: :wallets }, index: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.integer :transaction_type, null: false
      t.timestamps
    end
  end
end
