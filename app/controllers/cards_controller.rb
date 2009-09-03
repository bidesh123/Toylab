class CardsController < ApplicationController

  hobo_model_controller

  auto_actions :all
  auto_actions_for :aspects, :create
  show_action :list

  def index
    hobo_index Card.top_level
  end

  def create
    hobo_create do
      if valid? then
        redirect_to params[:after_submit] << "\#edit-now-#{@card.id}"
      end
    end
  end

  def auto_kind
    @cards = Card.all(:conditions => ["LOWER(kind) LIKE ?", "#{params[:q].to_s.downcase}%"]).map(&:kind).uniq.sort
    render :action => :auto
  end

  def auto_name
    @cards = Card.all(:conditions => ["LOWER(name) LIKE ?", "%#{params[:q].to_s.downcase}%"]).map(&:reference_name).uniq.sort
    render :action => :auto
  end
end

