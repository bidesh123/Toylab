class Card < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name         :string
    body         :text
    kind         :string
    based_on     :string
    theme        enum_string(
      :pink, :orange, :yellow, :green, :blue, :purple, :grey)
    whole_id     :integer
    list_id      :integer
    timestamps
  end

  belongs_to :owner, :class_name => "User", :creator => true
  belongs_to :looks_like, :class_name => "Card", :foreign_key => "look_like_id"

  belongs_to :whole  , :class_name => 'Card', :foreign_key => :whole_id, :accessible => true
  has_many   :aspects, :class_name => 'Card', :foreign_key => :whole_id, :accessible => true, :dependent => :destroy

  belongs_to :list   , :class_name => 'Card', :foreign_key => :list_id , :accessible => true
  has_many   :items  , :class_name => 'Card', :foreign_key => :list_id , :accessible => true, :dependent => :destroy

  acts_as_list         :column => :number, :scope => :list

  named_scope :top_level, :conditions => ['list_id IS ? AND whole_id IS ?', nil, nil]

  after_create :generate_looks_like

  def generate_looks_like
    return if look_like_id.blank?
    return unless source_card  = Card.find(look_like_id)
    return unless source_items = source_card.items(:order => "updated_at DESC")
    
    source_item = source_items[0]
    create_child_aspects do
      generate_aspects_recursively(source_item)
    end if source_item
  end

  def generate_aspects_recursively source_item
    dest_item = self
    dest_item.kind = source_item.kind if source_item.kind
    source_item.aspects.each do |source_aspect|
      dest_aspect = self.aspects.create!(:kind => source_aspect.kind)
      dest_aspect.generate_aspects_recursively source_aspect
    end
  end

 # --- Toy --- #

  class HtmlTable < Array
    def rectangular! # changes are not destructive or cumulative
      most_rows = map { |column| column.length }.max
      each { |el| el[most_rows - 1] ||= nil } if most_rows > 0
    end
    def transpose
      length == 0 ? [] : (Array.new rectangular!).transpose
    end
  end

  def edit_deep
    {:origin => id}
  end

  def next_up
    whole_id || list_id || id
  end

  def numeric?
    true if Float(name) rescue false
  end

  def look_wider                 wide_context, deep, max_aspect_depth, aspect_depth
    sub            = Card.find id
    names          = deep[:columns][:names]
    cells          = deep[:columns][:cells]
    row            = deep[:row]
    column         = []
    column[row]    = [sub]
    indent         = "." * 999
    display_kind   = kind || "&nbsp;"
    wider_context  = wide_context + display_kind.to_s
    contexts       = wide_context.split(' - ')
    wider_context += ' - '
    deep[         :debug_log] += "<br /><br/>#{indent[0, aspect_depth*32]}"
    deep[         :debug_log] += "<br />Looking wider into #{reference_name}"
    deep[         :debug_log] += "<br />Is there an existing column for <- #{wider_context}>?"
    column_number = names.index(wider_context)
    if column_number           # column already exists
      cells[column_number][row] ||= []
      cells[column_number][row] << sub # this changes deep[:column][:cells]
      deep[       :debug_log] += "<br/>Yes! It's there, in column #{column_number} of <br>---#{names.join '<br>---'},"
      deep[       :debug_log] += "<br/>so I add column #{column_number} of line #{row} to #{cells[column_number][row]}"
    elsif names.length == 0    # there are no columns yet
      cells << column          # changes deep[:column][:cells]
      names << wider_context   # changes deep[:column][:names]
      column_number = 0
      deep[       :debug_log] += "<br/>Nope. As a matter of fact, there are no existing columns at all"
      deep[       :debug_log] += "<br/> so we insert a new column called #{display_kind}"
      deep[       :debug_log] += "<br/> and populate line #{row}"
      deep[       :debug_log] += "<br/> with #{cells[column_number][row]}"
    else
      if kind.nil?
                                 # we need a vague column
        column_number = 0        # insert before first column
      else                       # there are existing columns
        deep[       :debug_log] += "<br/>but it's not in any of <br/>---#{names.join '<br>---'}"
        until (finished = contexts.length == 0) || column_number
          contexts.pop
          if finished
            column_number ||= -1                  # -1 is the rightmost position
          else
            context_string = contexts.join(d ||= ' - ') + d
            if names.include? context_string
              name_after_which_to_insert = names.reverse.detect do |c|
                c.match "^#{context_string}"
              end
              column_number = names.index(name_after_which_to_insert)
            end
          end
        end
        if column_number
          deep[     :debug_log] += "<br/>I find the subset <-#{context_string}> at column #{column_number}"
          column_number +=  1
        else
          deep[     :debug_log] += "<br/>I can't find the subset <-#{context_string}> anywhere"
          deep[     :debug_log] += "<br/> so i'd like to insert a new column after the last column"
          column_number  = -1
        end
      end
      names.insert(column_number, wider_context) # changes deep[:column][:names]
      cells.insert(column_number, column ) # changes deep[:column][:cells]
      deep[       :debug_log] += "<br/> and populate line #{row}"
      deep[       :debug_log] += "<br/> with #{cells[column_number][row]}"
      deep[       :debug_log] += "<br/> so that names becomes <br>---#{names.join '<br>---'}"
    end
    peek = deep[:columns][:cells].transpose.map do |the_row|
      the_row.map do |cell_list|
        (cell_list || []).join("<br />") #cell.name || cell.kind ? "a #{cell.kind}" : nil || "number #{cell.id}" rescue "nil"
      end.join "</td                     ><td class='debug'>"
    end.join   "</td></tr            ><tr><td class='debug'>"
    deep[         :debug_log] += "<br/>and the cells become"
    deep[         :debug_log] += "<br/><table ><tr><td class='debug'>#{peek}" +
                                 "</td></tr></table>"
    unless (aspect_depth += 1) >= max_aspect_depth
      aspects.each do |aspect|
        deep = aspect.look_wider wider_context, deep, max_aspect_depth, aspect_depth
      end
    end
    aspect_depth -= 1
    deep
  end

  def look_deeper               wide_context, deep, max_item_depth = 2, max_aspect_depth = 9, item_depth = 0
    indent = "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
    deep[         :debug_log] += "<br /><br/>#{indent[0, item_depth*2]}==================================================================="
    deep[         :debug_log] += "<br />after #{ deep[:row] } rows"
    deep[         :debug_log] += "<br /><br/> Looking deeper into #{reference_name}"
    deep[         :debug_log] += "<br />It has #{items.length} subitems"
    unless item_depth == 0
      deep = look_wider         wide_context, deep, max_aspect_depth, 0
      deep[:row] += 1
    end
    unless (item_depth += 1) >= max_item_depth
      deep[       :debug_log] += "<br />item_depth is #{item_depth} out of #{max_item_depth}"
      items.each do |item|
        deep = item.look_deeper wide_context, deep, max_item_depth, max_aspect_depth, item_depth
      end
    end
    item_depth -= 1
    deep
  end

  def look_deep max_item_depth = 2, max_aspect_depth = 9
    look_deeper \
      ""                                    ,  #no context
      {                                        #deep
        :root                    => id   ,
        :row                     => 0    ,
        :columns                 => {
            :names => HtmlTable.new   ,
            :cells => HtmlTable.new
        }                                ,
        :debug_log               => ''
      }                                     ,
      max_item_depth                        ,  #optional
      max_aspect_depth                      ,  #optional
      0                                        #item_depth
  end

  def column_name_rows deep
    columns = deep[:columns][:names]
    column_names = columns.map do |a|
      a.split(" - ")
    end
    number_of_name_rows = column_names.map { |c| c.length }.max
    column_names.each do |el|
      el[number_of_name_rows] ||= nil
    end
    column = -1
    name_rows = []
    column_names.each do |name_column|
      column += 1
      name_rows[column]=[]
      row = -1
      name_column.each do |name_cell|
        name_rows[row += 1]       ||= []
        name_rows[row     ][column] = name_cell
      end
    end
    name_rows
  end

  def reference_name
    if name.nil? || name.length == 0      
      (kind.nil? || kind.length == 0 ? "card ##{id}" : "Unspecified " + kind)
    else
      last_char  = name.to_s[-1]
      first_char = name.to_s[ 0]
      toy_numeric = name.is_a?(Numeric)      ||
        (last_char  >= 48 && last_char  <= 57) ||
        (first_char >= 48 && first_char <= 57)
      toy_numeric ? [kind.to_s, name].join(" "): name
    end
  end

  def deep_aspects
    deeper_aspects
  end

  def deep_items
    deeper_items
  end

  def deeper_aspects max_depth = 9, depth = 0
    r = [ {:depth => depth, :item => self} ]
    return r if depth >= max_depth
    aspects.each do |aspect|
      r.concat aspect.deeper_aspects depth + 1
    end
    r
  end

  def deeper_items max_depth = 9, depth = 0
    r = [{:depth => depth, :item => self}]
    unless depth >= max_depth
      items.each do |item|
        r.concat item.deeper_items   depth + 1
      end
    end
  end

 # --- Permissions --- #

 def creating_child_aspects?
   Thread.current["creating_child_aspects"]
 end

 def create_child_aspects
   raise "Must pass block to yield to" unless block_given?
   Thread.current["creating_child_aspects"] = true
   yield
 ensure
   Thread.current["creating_child_aspects"] = false
 end

  def create_permitted?
    return true if owner_or_admin?
    return false unless acting_user.signed_up?

    if whole_id then
      Card.find(whole_id).owner_is?(acting_user)
    else
      whole_id.nil? || creating_child_aspects?
    end
  end

  def update_permitted?
    return true if owner_or_admin?
    return false unless acting_user.signed_up?

    only_changed?(:name, :body, :theme)
  end

  def destroy_permitted?
    owner_or_admin?
  end

  def view_permitted?(field)
    true
  end

  def owner_or_admin?
    owner_is?(acting_user) || acting_user.administrator?
  end
end
