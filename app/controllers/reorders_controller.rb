class ReordersController < ApplicationController
  def create
    @card   = Card.find(params[:card_id])
    @target = Card.find(params[:target_id])
    @card.move_to!(@target)
    render :nothing => true, :status => :created
  end
end
