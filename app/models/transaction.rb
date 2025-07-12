# frozen_string_literal: true

class Transaction < ApplicationRecord
  belongs_to :wallet
  belongs_to :initiator, class_name: "Wallet", foreign_key: "initiator_id", optional: true
  belongs_to :receiver, class_name: "Wallet", foreign_key: "receiver_id", optional: true

  enum transaction_type: { deposit: 0, withdrawal: 1, transfer: 2 }

  validates :amount, presence: true, numericality: { greater_than: 0, precision: 15, scale: 2 }
  validate :validate_transfer_wallets, if: :transfer?

  private

  def validate_transfer_wallets
    if initiator.blank? || receiver.blank?
      errors.add(:base, "Both initiator and receiver must be present for transfers")
    elsif initiator_id == receiver_id
      errors.add(:base, "Initiator and receiver must be different")
    end
  end
end
