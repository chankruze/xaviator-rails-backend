module Api
  module V1
    class AviatorRoundsController < ApplicationController
      before_action :authenticate_request!  # JWT protected
      before_action :set_round, only: %i[show bet]

      # GET /api/v1/aviator_rounds
      def index
        rounds = AviatorRound.order(created_at: :desc).limit(50)
        json_response(rounds.as_json(only: [ :id, :status, :betting_duration, :created_at, :updated_at ]))
      end

      # GET /api/v1/aviator_rounds/:id
      def show
        round = AviatorRound.includes(bets: :user).find(params[:id])
        json_response(
          round.as_json(
            only: [ :id, :status, :betting_duration, :created_at, :updated_at ],
            include: {
              bets: {
                only: [ :id, :amount, :status ],
                include: {
                  user: { only: [ :id, :email ] }
                }
              }
            }
          )
        )
      end

      # POST /api/v1/aviator_rounds/:id/bet
      def bet
        amount = bet_params[:amount].to_f
        return json_error("Invalid amount") if amount <= 0

        # TODO: Ensure betting phase is active
        unless @round.betting?
          return json_error("Cannot place bet, round is not in betting phase", status: :forbidden)
        end

        # Find existing bet for this user and round
        existing_bet = @round.bets.find_by(user: current_user)

        if existing_bet
          # Merge: Add new amount to existing bet
          existing_bet.update!(amount: existing_bet.amount + amount)
          bet = existing_bet
        else
          # Create a new bet
          bet = @round.bets.create!(user: current_user, amount: amount)
        end

        json_notice("Bet placed successfully", bet: bet)
      rescue ActiveRecord::RecordInvalid => e
        json_error(e.record.errors.full_messages.join(", "), status: :unprocessable_entity)
      end

      private

      def bet_params
        params.require(:aviator_round).permit(:amount)
      end

      def set_round
        @round = AviatorRound.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        json_error("AviatorRound not found", status: :not_found)
      end
    end
  end
end
