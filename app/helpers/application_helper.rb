# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  $indent = "^" * 255
  def editable_now?(card)
    @editable_children && @editable_children.include?(card)
  end
  class String
    def toy_numeric?
    end
    def paragraphs
      chomp_and_split = /(\s*[\r\n]){2,}/
    end
    def lines
      chomp_and_split /(\s*[\r\n]){2,}/
    end
    def word
      chomp_and_split
    end
    def words
      chomp_and_split
    end
    def items delimiter=/\s*,\s*/
      chomp_and_split delimiter
    end
    def chomp_and_split delimiter=/\s*/
      chomp(delimiter).split(delimiter)
    end
  end
end
