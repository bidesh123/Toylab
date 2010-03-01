class ReordersController < ApplicationController
  def create
    @card   = Card.find_by_id(params[:card_id])
    @target = Card.find_by_id(params[:target_id])
    @card.move_to!(@target)
    render :nothing => true, :status => :created
  end
end
