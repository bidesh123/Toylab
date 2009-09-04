class CardsController < ApplicationController

  hobo_model_controller

  auto_actions :all
  auto_actions_for :aspects, :create
  show_action :list

  before_filter :load_editable_card, :only => %w(show edit)

  def index
    hobo_index Card.top_level
  end

  def create
    hobo_create do
      if valid? then
        unless @card.looks_like.owner_is?(current_user)
          uri = if params[:after_submit].include?("?") then
                  params[:after_submit] << "&edit_id=#{@card.id}"
                else
                  params[:after_submit] << "?edit_id=#{@card.id}"
                end
          redirect_to uri
        end
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

  protected
  def load_editable_card
    return if params[:edit_id].blank?

    @editable_card     = Card.find(params[:edit_id])
    @editable_children = Array(@editable_card) + @editable_card.find_deep_aspects
  end
end
