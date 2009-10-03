class Guest < Hobo::Guest

  def administrator?
    false
  end
  def name
    "guest"
  end
end
