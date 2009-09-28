# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  $indent = "^" * 255
  def editable_now?(card)
    @editable_children && @editable_children.include?(card)
  end
end
