class AviatorRoundChannel < ApplicationCable::Channel
  def subscribed
    round_id = params[:round_id]
    stream_from "aviator_round_#{round_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
