module CardsHelper
  def mainly_tabular_view
    " table show report ".include? " #{controller.action_name} "
  end
end
