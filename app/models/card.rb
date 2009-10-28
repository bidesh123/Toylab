class Card < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name         :string
    body         :text
    kind         :string
    script       :text
    view         enum_string(:view    , :page   , :list  , :table   , :slide,
                             :none    , :custom , :tree  , :report  , :chart )
    access       enum_string(:access  , :private, :public, :shared  , :demo,
                             :auto                                                  )
    theme        enum_string(:theme   ,
                             :pink   , :orange, :yellow  , :green   , :purple,
                             :none                                                  )

    #context_id     :integer # Deprecated
    number         :integer # Deprecated

    list_position  :integer
    whole_position :integer
    table_position :integer

    timestamps
  end

  #0
  belongs_to :owner     , :class_name => "User", :creator => true

  #1
  belongs_to :list      , :class_name => 'Card', :foreign_key => :list_id    , :accessible => true
  has_many   :items     , :class_name => 'Card', :foreign_key => :list_id    , :accessible => true, :dependent => :destroy, :order => "list_position"

  #2
  belongs_to :whole     , :class_name => 'Card', :foreign_key => :whole_id   , :accessible => true
  has_many   :aspects   , :class_name => 'Card', :foreign_key => :whole_id   , :accessible => true, :dependent => :destroy, :order => "whole_position"

  #3
  belongs_to :table     , :class_name => 'Card', :foreign_key => :table_id   , :accessible => true
  has_many   :columns   , :class_name => 'Card', :foreign_key => :table_id   , :accessible => true, :dependent => :destroy, :order => "table_position"

  #4
  belongs_to :based_on  , :class_name => "Card", :foreign_key => :based_on_id, :accessible => true
  has_many   :instances , :class_name => 'Card', :foreign_key => :based_on_id, :accessible => true, :dependent => :destroy

  sortable :scope => :list_id,    :column => :list_position,  :list_name => :list
  sortable :scope => :whole_id,   :column => :whole_position, :list_name => :whole
  sortable :scope => :table_id,   :column => :table_position, :list_name => :table
  sortable :scope => :context_id, :column => :number # deprecated

  named_scope :top_level                                                               ,
     :conditions => ['list_id IS ? AND whole_id IS ? AND table_id IS ?', nil, nil, nil],
     :order => "created_at DESC"
#  named_scope :similar_instances, lambda {
#    {:conditions => ['kind    IS ? AND owner_id IS ?', kind, acting_user.id]}
#  }

  before_save do |c| c.context_id = c.whole_id || c.list_id end
  after_create :follow_up_on_create
# after_update :follow_up_on_update

  def source_group
    case
    when whole_id                   then :whole
    when table_id                   then :table
    when list_id                    then :list
    when suite?                     then :suites
    end
  end

  def destination_group
    original_group
    :table       if               whole_id &&  target.list && target.whole
    :table       if               whole_id &&  target.table
    :unsupported if table_id               &&  target.list
    :unsupported if list_id   &&  whole_id &&  target.list
    :unsupported if list_id   && !whole_id &&  target.table
    :unsupported if list_id   && !whole_id &&  target.list && target.whole
    :suites      if list_id   && !whole_id &&  target.suite?
    :unsupported if suite?                 &&  target.table
    :unsupported if suite?                 &&  target.list && target.whole
    :item        if suite?                 && !target.suite?
  end

  def move_to!(target)
    operation = self.horizontal? == target.horizontal? ? :insert : :add
    unless new_group = destination_group == :unsupported
      self.remove_from_list original_group
      case operation
      when :insert
        case new_group
        when :whole
          self.insert_at!(target.whole_position, :whole) if target.whole
        when :table
          self.insert_at!(target.table_position, :table) if target.table
        when :list
          self.insert_at!(target.list_position , :list ) if target.list
        else # :item, suite?
          self.insert_at! target.list_position , :list
        end
      when :add
        case new_group
        when :whole
          target.aspects << self
        when :table
          target.columns << self
        when :list
          target.items   << self
        else # :suite
           #error # you'd have to drag to the root.
           #is the root the suites button or the toy office logo ? or both?
        end
      else #error
      end
    end
  #to do what if you drag to the top item in the page!!!!? it should NOT become a peer
  #if it does, the redirect should be the context, at least one level
  end

  def context
    @context ||= case
                 when list_id
                   list
                 when whole_id
                   whole
                 when table_id
                   table
                 else #suite
                   nil
                 end
  end
  
  def context_id
     list_id ||  whole_id ||  table_id
  end

  def suite?
    !list_id && !whole_id && !table_id
  end

  def horizontal?
                 whole_id ||  table_id
  end

  def vertical?
     list    || !whole    && !table
  end

  def next_up_id
    context_id || id
  end

  def recursive_owner
    return owner unless owner.nil?
    context ? context.recursive_owner : owner
  end

  def recursive_access
    return access unless access == "access"
    c = context ? c.recursive_access : access
  end

  def inherit_from_columns this_list
    #self is new item
    cols = this_list.columns
    return false unless cols && cols.length > 0 && (first_column = cols.shift)
    update_attributes :based_on_id => first_column.id, :kind =>first_column.kind
    on_automatic do
      cols.each do |col|
        this_new_aspect = self.aspects.create!(
          :based_on_id => col.id,
          :kind        => col.kind
        )
        this_new_aspect.generate_aspects_recursively col
      end
    end
  end

  def generate_column_dependents this_table
    # self is a new column
    return unless dest_items = this_table.items    
    if this_table.columns.length == 1 #special case for no pre-existing columns
      on_automatic do
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
      on_automatic do
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

#  def follow_up_on_update
#    if it is a column name, update the kinds in the columns
#    elsif it is a name change, and it has a base
#      update the dependents
#      fill in the address from the customer
#    end
#  end

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

  def auto_view
    case self.view
    when "list", "slide", "table", "page", "report", "tree"
      self.view
    when "custom", "chart"
      "tree"
    else
      "report"
    end
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
    self.aspects.each do |asp|
      return true if asp.based_on_id == [prototype.id, prototype.based_on_id]
    end
    false
  end

  def inherit_by_example example
    return false if already_inherited(example)
    on_automatic do
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

  def self.new_suite
    on_automatic do
      Card.new  :body   => welcome ,
                :view   => 'page'  ,
                :access => 'shared'
    end
  end

  def self.welcome
    <<-QUOTe
      Welcome to your toy office suite.

      You may want to do a few things before you start
      1. Name your suite. Click on the grey title, type the new name, then click somewhere else.
      2. If you want text, such as this one on your lop level, simply click in this text, replace it, then click somewhere else..
      3. Or, if you just want to erase this text, click on it, press delete, then click somewhere else.

      Notice that you always click elsewhere when you are finished. Try it! You can't break anything...

       QUOTe
  end

  def on_automatic thread_name = "on automatic", &block
    self.class.on_automatic thread_name, &block
  end

  def self.on_automatic thread_name = "on automatic"
    raise "Must pass block to yield to" unless block_given?
    Thread.current[thread_name] = true
    yield
  ensure
    Thread.current[thread_name] = false
  end

  def self.on_automatic? thread_name = "on automatic"
    Thread.current[thread_name]
  end

  def on_automatic? thread_name = "on automatic"
    self.class.on_automatic? thread_name
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

  def numeric?
    true if Float(name) rescue false
  end

  def reference_name
    if name.blank?
      kind.blank? ? "Empty" : "Empty #{kind}"
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

  def owner_or_admin?
    owner_is?(acting_user) || acting_user.administrator?
  end

  def demo_level_requirements intent
logger.debug "Cap'n, will ye let me #{intent} the sandbag booty now?"
    case intent
    when :manage
      :administrator
    when :script
      :owner
    when :design
      :signed_in
    when :edit, :see
      :guest
    else
      :demo_error
    end
  end

  def shared_requirements intent
logger.debug "So Cap'n can I #{intent} this collar bone and shin doctor?"
    case intent
    when :manage
      :administrator
    when :script, :design
      :owner
    when :use
      :signed_in
    when :see
      :guest
    else
      :shared_error
    end
  end

  def public_requirements intent
logger.debug "Well, Cap'n do I #{intent} this publick docomant or not?"
    case intent
    when :manage
      :administrator
    when :script, :design, :use
      :owner
    when :see
      :guest
    else
      :public_error
    end
  end

  def create_permitted?
#    logger.debug "ahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaaha"
#    logger.debug self.to_yaml
return true
    if !context_id
      permitted? :create_suite
    elsif !context
      self.theme = "pink"
      permitted? :illegal
    elsif whole_id
      permitted? :add_aspect, whole.recursive_access
    elsif table_id
      permitted? :add_column, table.recursive_access
    elsif item_id
      permitted? :add_item  , list.recursive_access
    else
      permitted? "create_error;#{attribute.inspect}".to_sym
    end
  end

  def destroy_permitted?
    if !context_id
      permitted? :delete_suite
    elsif !context
      self.theme = "pink"
      permitted? :delete_suite
    elsif whole_id
      permitted? :delete_aspect, whole.recursive_access
    elsif table_id
      permitted? :delete_column, table.recursive_access
    elsif item_id
      permitted? :delete_item  , list.recursive_access
    else
      permitted? "destroy_error;#{attribute.inspect}".to_sym
    end
  end

  def edit_permitted?(attribute) #try_the_automatically_derived_version_first
    if    [:name, :body, :theme].include? attribute
      permitted? :edit_data
    elsif [:kind, :script].include? attribute
      permitted? :edit_structure
    else
      permitted? "edit_error;#{attribute.inspect}".to_sym
    end
  end

  def update_permitted?
    if only_changed?       :name, :body  , :theme
      permitted? :edit_data
    elsif only_changed?    :kind, :script, :name, :body  , :theme
      permitted? :edit_structure
    else
      permitted? "update_error;#{attribute.inspect}".to_sym
    end
  end

  def view_permitted?(field)
    case field
    when :name, :body, :theme
      permitted? :read
    when :kind
      true
    when :script
      permitted? :script
    when nil
      permitted? :read
    else
      permitted? :manage
    end
  end

  def permitted? demand
    intent = case demand
             when :manage
               :administrate
             when :add_aspect, :delete_aspect,
               :add_column, :delete_column,
               :delete_suite,
               :edit_structure, :script
               :design
             when :add_item, :delete_item, :edit_data
               :use
             when :new_suite
               :start
             when :read
               :see
             else#including :error, :dangling, :program_error, data_error, :illegal
               logger.debug "****error 9999999999999999999999999999999999999999999999999999: #{demand}"
               :unsupported_demand
             end
    logger.debug "Ahoy cap'n, don't shoot. I just be wantin to #{demand} #{self.inspect}! intent: #{intent.inspect}"
    intent_permitted? intent
  end

  def acting_user_with_logging=(*args)
    logger.debug {"==> acting_user=(#{args.inspect})"}
    #logger.debug { caller.join("\n") }
    send("acting_user_without_logging=", *args)
  end

  alias_method_chain :acting_user=, :logging

  def grant_permission? requirements
    logger.debug "Are ye #{requirements} for this #{self.reference_name} booty? We hang snoopers here! for #{acting_user.inspect}, owner: #{owner.inspect}"
    return true if on_automatic?

    acting_user.administrator? || case requirements
    when :guest
      true
    when :signed_up
      acting_user.signed_up?
    when :owner
      logger.debug {"==> Checking against #{recursive_owner.inspect}"}
      acting_user == recursive_owner
    when :administrator
      acting_user.administrator?
    else
      false
    end
  end

  def intent_permitted? intent
    access_level = self.recursive_access || "shared"
    logger.debug "Now let's see, lad. That would be a #{access_level} document ye be tryin to #{intent}! "

    requirements = case access_level
    when "demo"
      demo_requirements intent
    when "shared"
      shared_requirements intent
    when "public"
      public_requirements intent
    when "private"
      private_requirements intent
    when "access", "nil"
      context?
      private_requirements intent
    else
      :access_level_error
    end
    grant_permission? requirements
  end

  def private_requirements intent
logger.debug "So Cap'n may I #{intent} the private doc?"
    case intent
    when :manage
      :administrator
    when :script, :design, :use, :see
      :owner
    else
      :private_error
    end
  end

end
