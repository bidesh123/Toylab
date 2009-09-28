class Card < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name         :string
    body         :text
    kind         :string
    script       :text
    theme        enum_string(:theme, :pink, :orange, :yellow, :green, :purple)
    context_id   :integer
    timestamps
  end

  #0
  belongs_to :owner     , :class_name => "User", :creator => true

  #1
  belongs_to :list      , :class_name => 'Card', :foreign_key => :list_id    , :accessible => true
  has_many   :items     , :class_name => 'Card', :foreign_key => :list_id    , :accessible => true, :dependent => :destroy, :order => "number"

  #2
  belongs_to :whole     , :class_name => 'Card', :foreign_key => :whole_id   , :accessible => true
  has_many   :aspects   , :class_name => 'Card', :foreign_key => :whole_id   , :accessible => true, :dependent => :destroy, :order => "number"

  #3
  belongs_to :table     , :class_name => 'Card', :foreign_key => :table_id   , :accessible => true
  has_many   :columns   , :class_name => 'Card', :foreign_key => :table_id   , :accessible => true, :dependent => :destroy, :order => "number"

  #4
  belongs_to :based_on  , :class_name => "Card", :foreign_key => :based_on_id, :accessible => true
  has_many   :instances , :class_name => 'Card', :foreign_key => :based_on_id, :accessible => true, :dependent => :destroy

  acts_as_list :column => :number, :scope => :context

  named_scope :top_level        ,
     :conditions  => ['list_id IS ? AND whole_id IS ?', nil, nil]
  named_scope :similar_instances, lambda {
    {:conditions => ['kind    IS ? AND owner_id IS ?', kind, current_user.id]}
  }

  before_save do |c| c.context_id = c.whole_id || c.list_id || c.table_id end
  after_create :generate_dependents
  #after_update :on_change

#  def on_change
#    if it is a column name, update the kinds in the columns
#    elsif it is a name change, and it has a base
#      update the dependents
#      fill in the address from the customer
#    end
#  end

  after_update
  #subsume existing aspects when creating columns
  

  def look_wider                 wide_context, deep, max_aspect_depth, aspect_depth
    names          = deep[:columns][:names]
    cells          = deep[:columns][:cells]
    row            = deep[:row]
    logger.debug :row
    logger.debug row
    column         = []
    column[row]    = [itself]
    coded_kind     = base ? "#{based_on_id}=>" : (kind || "&nbsp;")
    logger.debug :coded_kind
    logger.debug coded_kind
    wider_context  = wide_context + coded_kind.to_s
    contexts       = wide_context.split(' - ')
    wider_context += ' - '
    deep[         :debug_log] += "<br /><br/>#{$indent[0, aspect_depth*32]}"
    deep[         :debug_log] += "<br />Looking wider into #{reference_name}"
    deep[         :debug_log] += "<br />Is there an existing column for <- #{wider_context}>?"
    column_number     = names.index(wider_context)
    if column_number
      deep[       :debug_log] += "<br/>Yes! It's there, in column #{column_number} of <br>---#{names.join '<br>---'},"
      deep[       :debug_log] += "<br/>so I add column #{column_number} of line #{row} to #{cells[column_number][row]}"
      column_exists cells, column_number, row
    elsif names.length == 0
      deep[       :debug_log] += "<br/>Nope. As a matter of fact, there are no existing columns at all"
      deep[       :debug_log] += "<br/> so we insert a new column called #{coded_kind}"
      deep[       :debug_log] += "<br/> and populate line #{row}"
      column_number = no_column_yet wider_context, names, cells, column
      deep[       :debug_log] += "<br/> with #{cells[column_number][row]}"
    else
      deep[       :debug_log] += "<br/> and populate line #{row}"
      column_number = there_are_existing_columns wider_context, column, contexts, names, cells, deep
      deep[       :debug_log] += "<br/> with #{cells[column_number][row]}"
      deep[       :debug_log] += "<br/> so that names becomes <br>---#{names.join '<br>---'}"
    end
    peek = deep[:columns][:cells].transpose.map do |the_row|
      the_row.map do |cell_list|
        (cell_list || []).join("<br />")
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

  def look_deeper               wide_context, deep, max_item_depth = 9, max_aspect_depth = 9, item_depth = 0
    deep[         :debug_log] += "<br /><br/>#{$indent[0, item_depth*2]}==================================================================="
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

  def look_deep max_item_depth = 9, max_aspect_depth = 9
    look_deeper \
      ""                                    ,  #no context
      {                                        #deep
        :root                    => id   ,
        :row                     => 0    ,
        :columns                 => {
            :column_ids => HtmlTable.new   ,
            :names => HtmlTable.new   ,
            :cells => HtmlTable.new
        }                                ,
        :debug_log               => ''
      }                                     ,
      max_item_depth                        ,  #optional
      max_aspect_depth                      ,  #optional
      0                                        #item_depth
  end

  def column_exists cells, column_number, row
    cells[column_number][row] ||= []
    cells[column_number][row] << itself # changes deep[:column][:cells]
    column_number 
  end
  
  def no_column_yet wider_context, names, cells, column
    cells << column                  # changes deep[:column][:cells]
    names << wider_context           # changes deep[:column][:names]
    0
  end
  
  def which_column contexts, names, deep
    column_number = 0
    if base || !kind.blank?               # we need a vague column
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
        column_number += 1
        deep[     :debug_log] += "<br/>I find the subset <-#{context_string}> at column #{column_number}"
      else
        deep[     :debug_log] += "<br/>I can't find the subset <-#{context_string}> anywhere"
        deep[     :debug_log] += "<br/> so i'd like to insert a new column after the last column"
        column_number - 1
      end
      column_number ? column_number + 1 : column_number - 1
    end
    deep[       :debug_log] += "<br/>but it's not in any of <br/>---#{names.join '<br>---'}"
    column_number
  end
  
  def there_are_existing_columns wider_context, column, contexts, names, cells, deep
    column_number = which_column contexts, names, deep
    names.insert(column_number, wider_context) # changes deep[:column][:names]
    cells.insert(column_number, column )       # changes deep[:column][:cells]
    column_number
  end
  
  def base
    @base_cache ||= based_on_id.blank? ? nil : Card.find(based_on_id)
  end

  def itself
    @itself_cache ||= Card.find id
  end

  def generate_dependents
    # in toy a thing, or ai block can inherit from several sources
    # it can have columns for its items to inherit from
      if    !table_id.blank? && this_table = Card.find(table_id)
       # self is a column
        if dest_items = this_table.items(:order => "number")
          logger.debug :id
          logger.debug id.to_yaml
          #create_dependents do
            dest_items.each do |dest_item|
             aspecs = dest_item.aspects
             dest_item.aspects.create!(
               :based_on_id => id, :kind => kind
             ) if dest_item
            end
        #  end
        end
    # it can inherit from its context
    # but not if it is an aspect. Why not, i need the script from this context to be active!!!
    # to do fg
      elsif !list_id.blank?  && this_list  = Card.find(list_id )
        if cols = this_list.columns(:order => "number") && key_column = cols[0]
          #first col is key column
          update_attribute :based_on_id, key_column.based_on_id
          update_attribute :kind       , key_column.kind
          cols.shift.each do |col|
            if col
              create_dependents do
                update_attribute :whole_id   , key_column.id
                update_attribute :based_on_id, col.based_on_id
                update_attribute :kind       , col.kind
                col.aspects.each do |source_aspect|
                  dest_aspect = self.aspects.create!(
                    :based_on_id => source_aspect.based_on_id,
                    :kind => source_aspect.kind)
                  dest_aspect.generate_aspects_recursively source_aspect
                end
              end
            end
          end
        elsif examples = this_list.items(:order => "updated_at DESC", :limit => 1)
          if example = examples[0] # last one modified
            create_dependents do
              generate_aspects_recursively example
            end
          end
        end
      end
    # it can inherit from its column
      if base
        create_dependents do
          generate_aspects_recursively base
          # it can inherit from its nature
        end
      elsif !kind.blank? && example = Card.find_by_kind(kind, :order => "updated_at DESC")
        create_dependents do
          generate_aspects_recursively example
        end
      end
    #end
  end

  def generate_aspects_recursively source_item
    dest_item = self
    dest_item.kind = source_item.kind if source_item.kind
    source_item.aspects.each do |source_aspect|
      dest_aspect = self.aspects.create!(:kind => source_aspect.kind)
      dest_aspect.generate_aspects_recursively source_aspect
    end
  end

  def create_dependents
    raise "Must pass block to yield to" unless block_given?
    Thread.current["creating_dependents"] = true
    yield
  ensure
    Thread.current["creating_dependents"] = false
  end

  def column_name_rows deep
    names        = deep[:columns][:names]
    column_names = names.map do |column_name|
      column_name.split(" - ")
    end
    number_of_name_rows = column_names.map { |c| c.length }.max
    column_names.each do |el|
      el[number_of_name_rows - 1] ||= nil
    end
    column    = -1
    name_rows  = [        ]
    column_names.each do |column_name|
      column += 1
      row              = -1
      column_name.each do |column_name_cell|
        name_rows[row += 1] ||= [      ]
        name_rows[row     ]     [column] = column_name_cell
      end
    end
    name_rows
  end

  #caching
  #def self.find
  #  super
  #end

  def move_to!(target)
    remove_from_list
    update_attributes( :list => nil,         :whole => target.whole) if target.whole
    update_attributes( :list => target.list, :whole => nil         ) if target.list
    #logger.debug {"==> Inserting at #{target.number}"}
    insert_at(target.number)
  end

  def find_deep_aspects
    returning([]) do |accumulator|
      find_deep_aspects_helper(accumulator)
    end.flatten
  end

  def find_deep_aspects_helper(accumulator)
    accumulator.push(aspects)
    aspects.each do |aspect|
      aspect.find_deep_aspects_helper(accumulator)
    end
  end
  protected :find_deep_aspects_helper

 def theme_class
   theme.blank? ? "" : "theme-#{theme.downcase}"
 end

 ## --- Toy --- #

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
      r.concat aspect.deeper_aspects(depth + 1)
    end
    r
  end

  def deeper_items max_depth = 9, depth = 0
    r = [{:depth => depth, :item => self}]
    unless depth >= max_depth
      items.each do |item|
        r.concat item.deeper_items(  depth + 1)
      end
    end
  end

 # --- Permissions --- #

 def creating_child_aspects?
   Thread.current["creating_child_aspects"]
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
