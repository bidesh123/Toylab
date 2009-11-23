module CardsHelper
  def mainly_tabular_view
    " page show report ".include? " #{controller.action_name} "
  end
end
