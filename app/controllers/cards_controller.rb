class CardsController < ApplicationController
  hobo_model_controller

  auto_actions :all
  auto_actions_for :aspects, :create
  show_action :report
  show_action :table
  show_action :page
  show_action :tree
  show_action :opus
  show_action :slide
  show_action :set_pad
  show_action :show_aspects
  show_action :show_body
  show_action :show_script
  show_action :show_items
  show_action :hide_aspects
  show_action :hide_body
  show_action :hide_script
  show_action :hide_items
  show_action :list
  show_action :custom
  index_action :manage

  before_filter :load_editable_card, :only => %w(show edit)
  before_filter :load_parent_card  , :only => %w(auto_kind auto_name)
  before_filter :grab_session

  def grab_session
    @states = session[:states]
  end

  def click
    raise "Kaboom"
  end

  def set_pad
    $CURRENT_PAD = params[:id].to_i == 0 ? nil : params[:id]
    # global is implemented as session in rails
    redirect_to :back
  end

  def show_aspects
    set_the_current :aspects  , :visibility, 'on'
    redirect_to :back
  end

  def show_body
    set_the_current :body     , :visibility, 'on'
    redirect_to :back
  end

  def show_script
    set_the_current :script   , :visibility, 'on'
    redirect_to :back
  end

  def show_items
    set_the_current :items    , :visibility, 'on'
    redirect_to :back
  end

  def hide_aspects
    set_the_current :aspects  , :visibility, 'off'
    redirect_to :back
  end

  def hide_body
    set_the_current :body     , :visibility, 'off'
    redirect_to :back
  end

  def hide_script
    set_the_current :script   , :visibility, 'off'
    redirect_to :back
  end

  def hide_items
    set_the_current :items    , :visibility, 'off'
    redirect_to :back
  end

  def show
    redirect_to :action => "edit"
  end

  def report
    hobo_show do
      this.update_attribute(:view, "report")
      render :action => this.auto_view
    end
  end

  def table
    hobo_show do
      this.update_attribute(:view, "table")
      render :action => this.auto_view
    end
  end

  def page
    hobo_show do
      this.update_attribute(:view, "page")
      render :action => this.auto_view
    end
  end

  def opus
    hobo_show do
      this.update_attribute(:view, "opus")
      render :action => this.auto_view
    end
  end

  def tree
    hobo_show do
      this.update_attribute(:view, "tree")
      render :action => this.auto_view
    end
  end

  def slide
    hobo_show do
      this.update_attribute(:view, "slide")
      render :action => this.auto_view
    end
  end

  def list
    hobo_show do
      this.update_attribute(:view, "list")
      render :action => this.auto_view
    end
  end

  def manage
    hobo_index Card
  end

  def index
    hobo_index Card.suites
  end

  def create
    hobo_create do
      if valid? then
        if true || @card.list && @card.list.owner_is?(current_user)
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

  def auto_kind #???
    # NOTE: To remove LOWER(name), remove the SQL condition and the 2nd Array element ====================================
    @cards = Card.all(:conditions => [
                      "LOWER(kind) LIKE ? AND LOWER(name) = ?",
                      "#{params[:q].to_s.downcase}%",
                      @parent_card.name]).map(&:kind).uniq.sort
    render :action => :auto
  end

  def auto_name #???
    @cards = Card.all(:conditions => [
                      "LOWER(name) LIKE ? AND LOWER(kind) = ?",
                      "%#{params[:q].to_s.downcase}%",
                      @parent_card.kind]).map(&:reference_name).uniq.sort
    render :action => :auto
  end

  protected
  def load_editable_card
    return if params[:edit_id].blank?

    @editable_card     = Card.find_by_id(params[:edit_id])
    @editable_children = Array(@editable_card) + @editable_card.find_deep_aspects
  end

  def load_parent_card
    @parent_card = Card.find_by_id(params[:parent_id])
  end

end
