class CardsController < ApplicationController

  hobo_model_controller

  auto_actions :all
  auto_actions_for :aspects, :create

  def index
    hobo_index Card.top_level
  end

end

