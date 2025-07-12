# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      private

      def authenticate_user!
        header = request.headers["Authorization"]
        header = header.split(" ").last if header
        begin
          decoded = JWT.decode(header, Rails.application.secret_key_base, true, { algorithm: "HS256" })
          @current_user = User.find(decoded[0]["user_id"])
        rescue JWT::DecodeError
          render json: { error: "Invalid token" }, status: :unauthorized
        rescue ActiveRecord::RecordNotFound
          render json: { error: "User not found" }, status: :unauthorized
        end
      end

      def current_user
        @current_user
      end
    end
  end
end
