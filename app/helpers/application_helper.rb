# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def editable_now?(card)
    @editable_children && @editable_children.include?(card)
  end
end
