# frozen_string_literal: true

class Wallet < ApplicationRecord
  belongs_to :user

  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0, precision: 15, scale: 2 }
  validates :user_id, uniqueness: true
end
