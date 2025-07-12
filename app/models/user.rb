# frozen_string_literal: true

class User < ApplicationRecord
  has_one :wallet, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  after_create :create_wallet

  private

  def create_wallet
    self.create_wallet!(balance: 0.0)
  end
end
