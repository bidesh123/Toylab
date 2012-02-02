require File.dirname(__FILE__) + '/../test_helper'

class CardTest < ActiveSupport::TestCase
  def test_permission_granted_when_on_automatic
    # setup
    card = Card.new

    # act
    Card.on_automatic do
      # verify
      assert card.grant_permission(:owner)
    end
  end
end
