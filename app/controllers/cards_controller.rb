class CardsController < ApplicationController

  hobo_model_controller

  auto_actions :all
  auto_actions_for :aspects, :create
  show_action :list
  show_action :slide
  show_action :report
  show_action :tree
  show_action :page
  show_action :table

  before_filter :load_editable_card, :only => %w(show edit)

  def show
    hobo_show
  end

  def index
    hobo_index Card.top_level
  end

  def create
    hobo_create do
      if valid? then
        if @card.list && @card.list.owner_is?(current_user)
        else
          if params[:after_submit].present? then
            uri = params[:after_submit]
            uri.gsub!(/(?:\?|&)?edit_id=\d+/, "")
            if uri.include?("?") then
              uri << "&edit_id=#{@card.id}"
            else
              uri << "?edit_id=#{@card.id}"
            end

            redirect_to uri
          else
            redirect_to @card
          end
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
