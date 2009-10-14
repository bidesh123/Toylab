class Card < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name         :string
    body         :text
    kind         :string
    script       :text
    view         enum_string(:view , :page  , :list, :table, :slide,
                             :none , :custom, :tree, :report, :chart )
    theme        enum_string(:theme, :pink, :orange, :yellow, :green, :purple,
                             :none                                   )
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

  acts_as_list :column => :number, :scope =>  :context
# sortable                         :scope => [:list_id, whole_id, table_id]

  named_scope :top_level        ,
     :conditions => ['list_id IS ? AND whole_id IS ? AND table_id IS ?', nil, nil, nil], :order => "created_at DESC"
#  named_scope :similar_instances, lambda {
#    {:conditions => ['kind    IS ? AND owner_id IS ?', kind, current_user.id]}
#  }

  before_save do |c| c.context_id = c.whole_id || c.list_id end
  after_create :follow_up_on_create
# after_update :follow_up_on_update

#  def what_to_do_after_a_change
#    if it is a column name, update the kinds in the columns
#    elsif it is a name change, and it has a base
#      update the dependents
#      fill in the address from the customer
#    end
#  end

  def inherit_from_columns this_list
    #self is new item
    cols = this_list.columns :order => "number"
    return false unless cols && cols.length > 0 && (first_column = cols.shift)
    update_attributes :based_on_id => first_column.id, :kind =>first_column.kind
    cols.each do |col|
      create_dependents do
        this_new_aspect = self.aspects.create!(
          :based_on_id => col.id,
          :kind        => col.kind
        )
        this_new_aspect.generate_aspects_recursively col
      end if col
    end
  end

  def generate_column_dependents this_table
    # self is a new column
    return unless dest_items = this_table.items    
    if this_table.columns.length == 1 #special case for no pre-existing columns
      create_dependents do
#       if (base = self.table.based_on) &&
#          (cols = base.columns)        &&
#          (col = cols[0])
#         update_attributes :based_on_id => col.id  ,
#                           :kind        => col.kind
        dest_items.each do |dest_item|
          dest_item.update_attributes(:based_on_id => id  ,
                                      :kind        => kind) if dest_item
        end
        generic_row = this_table.columns.create!
      end
    else
      create_dependents do
        dest_items.each do |dest_item|
          dest_item.aspects.create!(
            :based_on_id => self.id,
            :kind        => self.kind
          ) if dest_item
        end
      end
    end
  end

  def generate_aspects_recursively source_item
    dest_item = self
    dest_item.kind = source_item.kind if source_item.kind
    source_item.aspects.each do |source_aspect|
      dest_aspect = self.aspects.create!(
        :based_on_id => source_aspect.id,
        :kind        => source_aspect.kind
      )
      dest_aspect.generate_aspects_recursively source_aspect
    end
  end

  def follow_up_on_create # in toy an item, or AI BLOC can inherit from several sources
    if    !table_id.blank? && this_table = Card.find(table_id)
      generate_column_dependents this_table # new columns are inherited from in each row
    elsif !list_id.blank?  && this_list  = Card.find(list_id )            # it can inherit from its list
      # why not from its whole? i need at least the script from the context to be active!!! to do fg
      inherit_from_columns(this_list) || inherit_from_siblings(this_list) # it can inherit from the columns,or from its siblings
      inherit_from_base               || inherit_from_kind                # it can inherit from its kind
    end
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
      else
        column_number - 1
      end
      column_number ? column_number + 1 : column_number - 1
    end
    column_number
  end

  def inherit_from_siblings this_list
    siblings = this_list.items(:order => "updated_at DESC", :limit => 1)
    if this_sibling = siblings[0] # last one modified
     #inherit_by_example this_sibling
      true
    end
  end

  def inherit_from_base
    return false unless example = base
   #inherit_by_example example
    true
  end

  def inherit_from_kind
    return false unless this_kind = kind && example =
      Item.find_by_kind(this_kind, :order => "updated_at DESC", :limit => 1)
   #inherit_by_example example
    true
  end

  def already_inherited prototype
    self.aspects.m
  end

  def inherit_by_example example
    return false if already_inherited(example)
    create_dependents do
      generate_aspects_recursively example
    end
  end

  def look_wider                 wide_context, deep, max_aspect_depth, aspect_depth
    names          = deep[:columns][:names]
    cells          = deep[:columns][:cells]
    row            = deep[:row]
    column         = []
    column[row]    = [itself]
    coded_kind     = base ? "#{based_on_id}=>" : (kind || "&nbsp;")
    wider_context  = wide_context + coded_kind.to_s
    contexts       = wide_context.split(' - ')
    wider_context += ' - '
    column_number  = names.index(   wider_context)
    if column_number
      column_exists cells, column_number, row
    elsif names.length == 0
      column_number = no_column_yet              wider_context, column          , names, cells
    else
      column_number = there_are_existing_columns wider_context, column, contexts, names, cells, deep
    end
    peek = deep[:columns][:cells].transpose.map do |the_row|
      the_row.map do |cell_list|
        (cell_list || []).join("<br />")
      end.join "</td                     ><td class='debug'>"
    end.join   "</td></tr            ><tr><td class='debug'>"
    unless (aspect_depth += 1) >= max_aspect_depth
      aspects.each do |aspect|
        deep = aspect.look_wider wider_context, deep, max_aspect_depth, aspect_depth
      end
    end
    aspect_depth -= 1
    deep
  end

def look_wide
end

def look_deeper               wide_context, deep, max_item_depth = 9, max_aspect_depth = 9, item_depth = 0
    unless item_depth == 0
      deep = look_wider         wide_context, deep, max_aspect_depth, 0
      deep[:row] += 1
    end
    unless (item_depth += 1) >= max_item_depth
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
  
  def no_column_yet wider_context, column, names, cells
    cells << column                  # changes deep[:column][:cells]
    names << wider_context           # changes deep[:column][:names]
    0
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
    if name.blank?
      kind.blank? ? "office suite #{id}" : "Untitled #{kind}"
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
