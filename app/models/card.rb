class Card < ActiveRecord::Base
  hobo_model # Don't put anything above this

  fields do
    name         :string
    body         :text
    kind         :string
    script       :text
    view         enum_string(:view    , :page   , :list  , :table   , :slide ,
                             :none    , :custom , :tree  , :report  , :chart  )
    access       enum_string(:access  , :private, :public, :shared  , :demo  ,
                             :auto                                            )
    theme        enum_string(:theme   ,
                             :pink   , :orange, :yellow  , :green   , :purple,
                             :none                                            )
    list_position  :integer
    whole_position :integer
    table_position :integer

    timestamps
  end

  #0
  belongs_to :owner    , :class_name => "User"  , :creator => true

  #1
  belongs_to :list     , :class_name => "Card"  , :foreign_key => :list_id    , :accessible => true
  has_many   :items    , :class_name => "Card"  , :foreign_key => :list_id    , :accessible => true,
                         :dependent  => :destroy, :order       => "list_position"

  #2
  belongs_to :whole    , :class_name => "Card"  , :foreign_key => :whole_id   , :accessible => true
  has_many   :aspects  , :class_name => "Card"  , :foreign_key => :whole_id   , :accessible => true,
                         :dependent  => :destroy, :order       => "whole_position"

  #3
  belongs_to :table    , :class_name => "Card"  , :foreign_key => :table_id   , :accessible => true
  has_many   :columns  , :class_name => "Card"  , :foreign_key => :table_id   , :accessible => true,
                         :dependent  => :destroy, :order       => "table_position"

  #4
  belongs_to :based_on , :class_name => "Card"  , :foreign_key => :based_on_id, :accessible => true
  has_many   :instances, :class_name => "Card"  , :foreign_key => :based_on_id, :accessible => true,
                         :dependent  => :destroy

  sortable :scope => :list_id,    :column => :list_position,  :list_name => :list
  sortable :scope => :whole_id,   :column => :whole_position, :list_name => :whole
  sortable :scope => :table_id,   :column => :table_position, :list_name => :table
#  sortable :scope => :context_id, :column => :number # deprecated

  named_scope :top_level                                                               ,
     :conditions => ["list_id IS ? AND whole_id IS ? AND table_id IS ?", nil, nil, nil],
     :order => "created_at DESC"
#  named_scope :similar_instances, lambda {
#    {:conditions => ["kind    IS ? AND owner_id IS ?", kind, acting_user.id]}
#  }

  #before_save do |c| c.context_id = c.whole_id || c.list_id end
  after_create :follow_up_on_create
# after_update :follow_up_on_update

  def reported_view
    case view
    when "view", "none", nil
      "suite"
    when "custom"
      "custom suite"
    else
      view
    end
  end

  def source_group
    case
    when whole_id then :whole
    when table_id then :table
    when list_id  then :list
    when suite?   then :suites
    end
  end

  def destination_group
    source_group
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
      self.remove_from_list source_group
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

#  def number
#    case
#    when whole_id; whole_position
#    when table_id; table_position
#    else;          list_position
#    end
#  end
#
#  def number=(value)
#    attr = case
#           when whole_id; :whole_position
#           when table_id; :table_position
#           else;          :list_position
#           end
#    write_attribute(attr, value)
#  end
#
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
      ac if asp.based_on_id == [prototype.id, prototype.based_on_id]
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

#def look_wide
#end

def look_deeper               wide_context, deep, max_item_depth = 9, max_aspect_depth = 9, item_depth = 0
    unless item_depth == 0
      deep = look_wider       wide_context, deep, max_aspect_depth, 0
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
    "
     Welcome to your toy office suite.

     You may want to do a few things before you start
     1. Name your suite. Click on the grey title, type the new name, then click somewhere else.
     2. If you want text, such as this one on your lop level, simply click in this text, replace it, then click somewhere else..
     3. Or, if you just want to erase this text, click on it, press delete, then click somewhere else.

     Notice that you always click elsewhere when you are finished. Try it! You can't break anything...
    "
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

  def create_permitted?
#   logger.debug "ahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaahaaha"
#   logger.debug self.to_yaml
    demand = case
      when !context_id
        :add_suite
      when !context
        :error_context_not_found
      when whole_id
        :add_aspect
      when table_id
        :add_column
      when list_id
        :add_item
      else
        :error_invalid_creation_context
      end
    !forbidden? demand
  end

  def destroy_permitted?
    demand = case
      when !context_id
        :delete_suite
      when !context
        :delete_orphan
      when whole_id
        :delete_aspect
      when table_id
        :delete_column
      when list_id
        :delete_item
      else
        :error_invalid_destruction_context
      end
    permitted? demand
  end

  def edit_permitted?(attribute) #try_the_automatically_derived_version_first
    demand = case attribute
      when nil
        :see
      when              :id            , :created_at   , :updated_at,
                        :based_on_id   , :owner_id     , :owner,
                        :whole_id      , :list_id      , :table_id                                                                      :owner
        :program
      when              :whole_position, :list_position, :table_position
        :manage
      when              :script
        :script
      when              :access
        :control_access
      when              :kind, :view   , :based_on      ,
                        :whole         , :list          , :table

        :edit_structure
      when              :name, :body, :theme
        :edit_data
      else
        "error_edit_unknown_attribute_#{attribute.inspect}".to_sym
      end
    permitted? demand
  end

  def update_permitted?
    demand = case
      when any_changed?(:id,
                        :created_at    , :updated_at   ,
                        :based_on_id   , :owner_id     , :owner         ,
                        :whole_id      , :list_id      , :table_id      )
        :program
      when any_changed?(:whole_position, :list_position, :table_position)
        :manage
      when any_changed?(:script                                         )
        :script
      when any_changed?(:access                                         )
        :control_access
      when any_changed?(:kind, :view, :whole, :table                    )
        :edit_structure
      when any_changed?(:name, :body, :theme, :list                     )
        :edit_data
      else
        "error_unknown_attribute_changed"
    end
    permitted? demand
  end

  def view_permitted? attribute
    demand = case attribute
      when :id,
           :created_at   , :updated_at    , :based_on_id   , :owner_id,
           :list_id      , :whole_id      , :table_id      ,
           :list_position, :whole_position, :table_position,
           :list         , :whole         , :table         , :owner
        :manage
      when
        :see
      when nil, :name, :body, :theme, :view, :kind,
                :aspects, :items, :columns, :access, :based_on
        :see
      when :script
        :script
      when nil
        :see
      else
        "error_view_unknown_attribute_#{attribute.inspect}".to_sym
      end
    permitted? demand
  end

  def permitted? demand
    reason = forbidden? demand
    return !reason unless reason.is_a? String
    logger.debug "8888888888888888888888888888888888888888888888888"
    logger.debug "toy permission error"
    logger.debug "card: #{reference_name}"
    logger.debug "user: #{acting_user.name if acting_user}"
    logger.debug "owner: #{owner.name if owner}"
    logger.debug "demand #{demand.to_s}"
    logger.debug "reason #{reason.to_s}"
    seppukku
  end
  
  def forbidden? demand
    #logger.debug "Ahoy cap'n, don't shoot. I just be wantin to #{demand} #{self.reference_name}!"
    intent = case demand
      when :program
        :program
      when :manage, :delete_orphan
        :manage
      when :control_access
        :author
      when :script
        :script
      when :add_aspect, :delete_aspect,
           :add_column, :delete_column,
           :delete_suite,
           :edit_structure, :delete_item
        :design
      when :add_item
        :use
      when :edit_data
        :use
      when :add_suite
        :initiate
      when :see
        :see
      else
        return "unsupported_demand_#{demand.inspect}"
      end
    intent_forbidden? intent
  end

  def intent_forbidden?    intent
    inherited_access = recursive_access
#   logger.debug "Now let's see, lad. That would be a #{inherited_access} document ye be tryin to #{intent}! "
    requirements = case inherited_access
      when "demo"
        demo_requirements    intent
      when "shared"
        shared_requirements  intent
      when "public"
        public_requirements  intent
      when "private"
        private_requirements intent
      else
        shared_requirements  intent
      end
    permission_withheld? requirements
  end

  def who
    (acting_user || Guest).name
  end

  def permission_withheld? requirements
    logger.debug
      "#{who}!" +
      "Are ye at least #{requirements}" +
      "for owner: #{owner.name if owner}'s" +
      "#{self.reference_name}?"
    return false if on_automatic? || acting_user.administrator?
#   logger.debug "I can see yer not an administrator."
    withheld = case requirements
    when :guest
#     logger.debug "this only needs a guest"
      false
    when :signed_up
      logger.debug "this needs a signed_up user, which #{who} #{acting_user.signed_up? ? 'is' : 'is NOT'}"
      !acting_user.signed_up?
    when :owner
      inherited_owner = recursive_owner.inspect
      logger.debug "You must be the owner! You #{acting_user == inherited_owner ? 'are': 'are NOT'}!"
#     logger.debug {"==> Checking against #{recursive_owner.inspect}"}
      acting_user != inherited_owner
    when :administrator
#      logger.debug "this needs an administrator"
      !acting_user.administrator?
    else
      logger.debug "this seems to need #{requirements}"
      requirements
    end
    logger.debug "PERMISSION WITHHELD" if withheld
    withheld
  end

  def acting_user_with_logging=(*args)
    logger.debug {"==> acting_user=(#{args.inspect})"}
    logger.debug { %Q(caller\n#{caller.join("\n")}) } unless args[0]
    send("acting_user_without_logging=", *args)
  end

#  alias_method_chain :acting_user=, :logging

  def demo_requirements intent
#   logger.debug "So Cap'n can I #{intent} this shared booty?"
    return :signed_up if intent == :design
    return :guest     if intent == :use
    shared_requirements intent
  end

  def shared_requirements intent
#   logger.debug "So Cap'n can I #{intent} this shared booty?"
    return :signed_up if intent == :use
    public_requirements intent
  end

  def public_requirements intent
#   logger.debug "Well, Cap'n do I #{intent} this publick dock you meant or not?"
    return :guest     if intent == :see
    private_requirements intent
  end

  def private_requirements intent
#   logger.debug "So Cap'n may I #{intent} the private doc?"
    tightest_requirements intent
  end

  def tightest_requirements intent
#   logger.debug "So Cap'n may I #{intent} the private doc?"
    case intent
    when :program, :manage
      :administrator
    when :author, :script, :design, :use, :see
      :owner
    when :initiate
      :signed_up
    else # not :program, :manage, :author, :script, :design, :use, :initiate, :see
      "unknown_intent_#{intent.to_s}_error".to_sym
    end
  end

  def recursive_owner
    if owner
      owner
    elsif context
      context.recursive_owner
    end
  end

  def recursive_access
    if access && access != "access"
      access
    elsif context
      context.recursive_owner
    else
      default_access
    end
    return access unless !access || access == "access"
    context ? context.recursive_access : default_access
  end

  def default_access
    "shared"
  end

end
