class Card < ActiveRecord::Base
  hobo_model # Don't put anything above this

#  require 'paperclip'
  
  module AttributeWatcher
  #  define_callbacks :attribute_changed
  #  attribute_changed :flag_attribute_changed
  #  def write_attribute(attr_name, value)
  #    returning(super) do
  #      @last_attribute_name = attr_name
  #      run_callbacks(:attribute_changed)
  #    end
  #  end
  #  private
  #    def flag_attribute_changed
  #    attribute = @last_attribute_name
  #    old_val, new_val = send("#{attribute}_change")
  #    logger.info "Changed! #{attribute} from #{old_val} to #{new_val}"
  #    end
  end

  fields do
    name             :string
    body             :text
    kind             :string
    script           :text
    pad              :boolean
    view             enum_string(:view   , :none  , :custom,
                                 :page   , :slide ,
                                 :list   , :opus  , :tree  ,
                                 :table  , :report, :chart                  )
    access           enum_string(:access ,
                                 :private, :public, :shared, :open , :closed)
    theme            enum_string(:theme  ,
                                 :pink   , :orange, :yellow, :green, :purple,
                                 :none                                      )
    list_position    :integer
    whole_position   :integer
    table_position   :integer
#    attachment_file_name    :string
#    attachment_content_type :string
#    attachment_file_size    :integer
#    attachment_updated_at   :datetime

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
  belongs_to :mold     , :class_name => "Card"  , :foreign_key => :mold_id    , :accessible => true
# has_many   :instances, :class_name => "Card"  , :foreign_key => :mold_id    , :accessible => true
  #5
  belongs_to :ref     , :class_name => "Card"   , :foreign_key => :ref_id      , :accessible => true
# has_many   :akas    , :class_name => "Card"   , :foreign_key => :ref_id      , :accessible => true
  #6
  belongs_to :suite    , :class_name => "Card"  , :foreign_key => :suite_id   , :accessible => true
  has_many   :parts    , :class_name => "Card"  , :foreign_key => :suite_id   , :accessible => true,
                         :dependent  => :destroy

  sortable :scope => :list_id , :list_name => :list ,  :column =>  :list_position
  sortable :scope => :whole_id, :list_name => :whole,  :column => :whole_position
  sortable :scope => :table_id, :list_name => :table,  :column => :table_position

  named_scope :suites    ,
     :conditions  => "suite_id IS NULL",
     :order       => "created_at DESC"

# named_scope :similar_instances, lambda { |suite_id|
#    {:conditions => ["kind    IS ? AND suite_id IS ?", kind, suite_id]}
#  }

#  named_scope :lookup, lambda { |nam, kind, suite_id, id| {
#    :conditions => [
#      "name = ? AND "                  +
#      "(kind = ? OR kind = NULL OR kind = '') AND " +
#      "suite_id = ? AND "              +
#      "id != ? AND "                   +
#      "ref_id IS NULL"                  ,
#                                 nam, kind, suite_id, id ] ,
#    :order => "created_at ASC"
#  }}

  named_scope :named    , lambda {             |nam | {
    :conditions   => ["name = ?"              , nam                    ]
  }}

  named_scope :as_a     , lambda {             |kind| {
    :conditions   => ["kind = ? OR kind = '' OR kind IS NULL"   , kind ]
  }}

  named_scope :part_of  , lambda {             |s_id| {
    :conditions   => ["suite_id = ?"          , s_id                   ]
  }}

  named_scope :but_not  , lambda {             |i_d | {
    :conditions   => ["id != ?"               , i_d                    ]
  }}

  named_scope :originals, lambda {                    {
    :conditions   => ["ref_id IS NULL"                                 ]
  }}

  named_scope :latest   , lambda {                    {
    :order        => "created_at DESC"
  }}

  has_attached_file :attachment,
#    :styles => {
#      :tiny => "35x35",
#      :preview => "175x175",
#      :large => "300x300"
#    },
    :storage => :s3,
    :s3_credentials => "#{RAILS_ROOT}/config/s3.yml",
    :path => ":attachment/:id/:style.:extension"           ,
    :bucket => 'toy-office-development'


  def suite_group
    recursive_suite || self
  end

  def init_from_s3_upload
    self.attachment_content_type =
      file_extension_content_type(self.attachment_file_name)
#      acl_obj = self.attachment.s3_object.acl
#      if acl_obj.grants.find { |g| g.to_s =~ /READ to AllUsers/ }
        self.acl = 'public-read'
#      else
#        self.acl = 'private'
#      end
  end

  before_save do |c|
    c.ensure_suite
  end

  def ensure_suite
    return unless !suite_id && context
    return unless (s = recursive_suite).is_a? Card
    suite = s unless s.id == id
  end

  def reset_suite!
    return unless context
    s_id = recursive_suite.id
    update_attribute :suite_id, s_id unless s_id == id
  end

  def after_create
    follow_up_on_create
    create_image_on_cloud if image?
  end

  def image?
    #return (attachment.content_type =~ /^image.*/) ? true : false
    (attachment.content_type =~ /^image.*/) ? true : false
  end

  def create_image_on_cloud
#    self.attachment.reprocess!
  end

  def file_extension_content_type filename
    types = MIME::Types.type_for(filename)
    types.empty? ? nil : types.first.content_type
  end

  before_update :prepare_for_update
  after_update  :follow_up_on_update

  def follow_up_on_update
#        logger.debug "follow up on updateeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
#        logger.debug "@catch"
#        logger.debug "catch"
    return if on_automatic?
#        logger.debug "not on automaticccccccccccccccccc"
    on_automatic do
#          logger.debug "now yessssssssssssssssssssssssss"
      return unless name && k = recursive_kind
#          logger.debug "name: #{name}"
      names      = self.class.named(name)
#          logger.debug "#{names.length} namesssssssssss"
#          logger.debug "recursive_kind: #{k}"
      kinds      = names.as_a(k)
#          logger.debug "#{kinds.length} as a #{k}"
      suites     = kinds.part_of(suite_id)
#          logger.debug "#{suites.length} part of #{suite_id}"
      all_but    = suites.but_not(id)
#          logger.debug "#{all_but.length} but not #{id}"
      origs      = all_but.originals
#          logger.debug "#{origs.length} originals"
      candidates = origs.latest
#          logger.debug "candidatessssssssss"
#          logger.debug candidates.to_yaml
      match = candidates.detect {|c| c.recursive_kind == k}
      return unless match
#          logger.debug "match : #{match.id}"
#          logger.debug "uuuuuuuuuuuuuuuuuuuu"
      update_attributes :ref_id => match.id
    end
  end

  def prepare_for_update
    @catch = "hi"
  end

  def self.field reference
    case self.it.class.name
    when "Card"
      case reference
      when #standard field list
           nil             , :owner,
           :id             , :owner_id       ,
           :name           , :kind           , :attachment     ,
           :ref            , :mold           , :suite          ,
           :ref_id         , :mold_id        , :suite_id       ,
           :akas           , :instances      , :parts          ,

           :list_id        , :whole_id       , :table_id       ,
           :list_position  , :whole_position , :table_position ,
           :list           , :whole          , :table          ,
           :items          , :aspects        , :columns        ,

           :body           , :access         , :theme          ,
           :script         , :view           , :pad            ,
           :created_at     , :updated_at                       ,
           :attachment_file_name             ,
           :attachment_content_type          ,
           :attachment_file_size             ,
           :attachment_updated_at
        it.send reference
      else
        ""
      end
    else
      ""
    end
  end

  def self.set_field reference
    case self.it.class.name
    when "Card"
      case reference
      when
           nil             , :owner,
           :id             , :owner_id       ,
           :name           , :kind           , :attachment     ,
           :ref            , :mold           , :suite          ,
           :ref_id         , :mold_id        , :suite_id       ,
           :akas           , :instances      , :parts          ,

           :list_id        , :whole_id       , :table_id       ,
           :list_position  , :whole_position , :table_position ,
           :list           , :whole          , :table          ,
           :items          , :aspects        , :columns        ,

           :body           , :access         , :theme          ,
           :script         , :view           , :pad            ,
           :created_at     , :updated_at                       ,
           :attachment_file_name             ,
           :attachment_content_type          ,
           :attachment_file_size             ,
           :attachment_updated_at
        it.send("#{reference}=", val)
      else
        ""
      end
    else
      ""
    end
  end

  def edit_permitted?(attribute) #try_the_automatically_derived_version_first
    demand = case attribute
      when nil
        :see
      when
                             :owner                            ,
           :id             , :owner_id                         ,
           :ref            , :mold           , :suite          ,
           :ref_id         , :mold_id        , :suite_id       ,
           :akas                             , :parts          ,

           :list_id        , :whole_id       , :table_id       ,
           :list           , :whole          , :table          ,
           :items          , :aspects        , :columns        ,

           :body                             , :theme          ,
                             :view                             ,
           :created_at     , :updated_at
        :program
      when :list_position  , :whole_position , :table_position
        :manage
      when :script
        :script
      when                   :access
        :control_access
      when                   :kind                             ,
            :view          , :pad
        :edit_structure
      when :name                             , :attachment     ,
           :body                             , :theme          ,
                             :view                             ,
                             :instances                        ,
           :attachment_file_name             ,
           :attachment_content_type          ,
           :attachment_file_size             ,
           :attachment_updated_at
        :edit_data
      else
        "error_edit_unknown_attribute_#{attribute.inspect}".to_sym
      end
#    logger.debug "edit permitted on #{attribute.inspect} yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"
#    logger.debug "demand #{demand.to_yaml}"
    permitted? demand
  end

  def update_permitted?
#    logger.debug "changed yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"
#    logger.debug changed?.to_yaml
    demand = case
      when any_changed?(     :owner                            ,
           :id             , :owner_id                         ,
           :ref            , :mold           , :suite          ,
           :ref_id         , :mold_id        , :suite_id       ,
           :akas                             , :parts          ,

           :list_id        , :whole_id       , :table_id       ,
           :list           , :whole          , :table          ,
           :items          , :aspects        , :columns        ,

           :body                             , :theme          ,
                             :view                             ,
           :created_at     , :updated_at                       )
        :program
      when any_changed?(
           :list_position  , :whole_position , :table_position )
        :manage
      when any_changed?(
           :script                                             )
        :script
      when any_changed?(     :access                           )
        :control_access
      when any_changed?(     :kind                             ,
                             :view           , :pad            )
        :edit_structure
      when any_changed?(
           :name                             , :attachment     ,
           :attachment_file_name                               ,
           :attachment_updated_at                              ,
           :attachment_content_type                            ,
           :attachment_file_size                               ,
           :body                             , :theme          ,
                             :view                             ,
                             :instances                        ,
           :attachment_file_name             ,
           :attachment_content_type          ,
           :attachment_file_size             ,
           :attachment_updated_at                              )
        :edit_data
      when changed?
#        logger.debug "changed uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu"
#        logger.debug changed?.to_yaml
        "unknown attribute changed: #{changed?.to_s}"
      else #nothing is changed???
        :see
     end
    permitted? demand
  end

  def view_permitted? attribute
    demand = case attribute
      when                   :owner                            ,
           :id             , :owner_id                         ,
           :ref            , :mold           , :suite          ,
           :ref_id         , :mold_id        , :suite_id       ,
           :akas                             , :parts          ,

           :list_id        , :whole_id       , :table_id       ,
           :list_position  , :whole_position , :table_position ,
           :list           , :whole          , :table          ,

           :created_at     , :updated_at
        :manage
      when :script
        :script
      when                   :access
        :control_access
      when nil             ,
           :name           , :kind           , :attachment     ,
           :items          , :aspects        , :columns        ,
           :body                             , :theme          ,
                             :view           , :pad            ,
           :attachment_file_name             ,
           :attachment_content_type          ,
           :attachment_file_size             ,
           :attachment_updated_at
        :see
      else
        "error_view_unknown_attribute_#{attribute.inspect}".to_sym
      end
    permitted? demand
  end

  def core_image_row?
    true
  end

  def core_main_row? deep
    !deep[:no_aspects]
  end

  def core_name_row?
    true
  end

  def core_body_row? deep
    !deep[:no_bodies ]
  end

  def core_script_row? user
    viewable_by?(user, :script)
  end

  def core_bottom_controls_row?
    true
  end

  def nature
    #eventual support for inheritance vis is a, is, has a, has some, has many
  end

  def self.reset_suites
    find(:all).each {|c| c.reset_suite!}
  end

  def recursive_ref
    return unless r = ref
    r.recursive_ref_inner
  end

  def recursive_ref_inner
    return self unless r = ref
    r.recursive_ref_inner
  end

  def recursive_suite
    return self unless ctx = context
    ctx.recursive_suite
  end

  def initial_suite
    return self unless ctx = context
    ctx.recursive_suite
  end

  def source_mold source
    r = if source.kind then self.class.find_pad source.kind end
    r ||= source.recursive_kind_mold
  end

  def generate_dependents source
    return unless source.is_a? Card
    source.aspects.each do |sub_source|
      self.aspects.create! :mold_id => source_mold(sub_source).id
    end
    source.items.each   do |sub_source|
      self.items.create!   :mold_id => source_mold(sub_source).id
    end
  end

  def follow_up_on_create
    generate_dependents mold if mold || nature
  end

  def local_pads
    return [] unless list
    all = all_pads
    pads = list.items.map{|item| item.recursive_kind}.uniq.select {|p| find_pad p}
    pads.delete 'item'
    pads
  end

  def pertinent_pads
    [self.class.current_pad].concat local_pads
  end
      
  def self.current_pad
    return unless
      $CURRENT_PAD     &&
      current = self.find_by_id($CURRENT_PAD)
    current.kind unless (["", "none"].include? current.kind)
  end

  def all_pads
    self.class.all_pads
  end

  def self.all_pads
    pad_cards = self.find_all_by_pad(true,
      :order => "updated_at DESC",
      :conditions => ["kind > ?", "''"]) || []
    pad_cards.map!{|pad_card| pad_card.kind}
    pad_cards.uniq.sort.map{ |kind| self.find_pad kind}
  end

  def find_pad k
    k ||= kind
    return false unless k
    self.class.find_pad k
  end

  def self.find_pad kind
    return false unless kind
    self.find_by_kind(
      kind                                ,
      :order      => "updated_at DESC" ,
      :limit      => 1                 ,
      :conditions => ["pad = ? AND (kind = '#{kind}' OR kind = '' OR kind = NULL)", true]
    ) || default_pad
  end

  def self.default_pad
    nil # items[0]
  end

  def generate_column_cells this_table
    # self is a new column
    return unless dest_items = this_table.items    
    if this_table.columns.length == 1 #special case for no pre-existing columns
      on_automatic do
#       if (the_mold = self.table.mold) &&
#          (cols = the_mold.columns   ) &&
#          (col = cols[0]             )
#         update_attributes :mold_id => col.id  ,
#                           :kind        => col.kind
        dest_items.each do |dest_item|
          dest_item.update_attributes(:mold_id => id  ,
                                      :kind        => kind) if dest_item
        end
        this_table.columns.create! #1st column used for items, so introduce another
      end
    else
      on_automatic do
        dest_items.each do |dest_item|
          dest_item.aspects.create!(
            :mold_id => self.id,
            :kind        => self.kind
          ) if dest_item
        end
      end
    end
  end

  def mold_existing_items_on_this_column #first column
    # default dependence on the column at creation
    # items can be made independent later
    on_automatic do
      adada ; return unless first_item = table.items[0]
      return unless the_kind   = first_item.kind
      write_attribute(kind, the_kind)
      items.each do |item|
        if item.kind == the_kind
          item.mold = self
        else
          unforeseen(kind(of(item)))
        end
      end
    end
  end
  
# def follow_up_on_update
#   what has changed???
# end

  def inherit_from_siblings this_list
    return #disabled
    siblings = this_list.items(:order => "updated_at DESC", :limit => 1)
    if this_sibling = siblings[0] # last one modified
      inherit_by_example this_sibling
    end
  end

# Return the next higher item in the list.
  def higher_item
    return nil unless list_id
    Card.find :first,
      :conditions => "list_id = #{list_id} AND list_position > #{list_position}",
      :order => "list_position"
  end

  # Return the next lower item in the list.
  def lower_item
    return nil unless list_id
    Card.find :first,
      :conditions => "list_id = #{list_id} AND list_position < #{list_position}",
      :order => "list_position DESC"
  end

  def self.numbering_reset
    Thread.current[:numbering] = []
  end

  def self.numbering_push
    Thread.current[:numbering].push 0
  end

  def self.numbering_pop
    Thread.current[:numbering].pop
  end

  def self.numbering_increment
    Thread.current[:numbering][-1] += 1
  end

  def self.numbering_list
    Thread.current[:numbering]
  end

  def self.recursive_numbering
    Thread.current[:numbering].map{|x| x.to_s}.join "."
  end

  def same_heading_stack?  desired, existing, deep, mode = :normal
    last_row = case mode
      when :partial
        desired.length - 1
      else
        [desired.length, existing.length].max
      end
    (0..last_row).each do |row|
      return false if different_heading? desired[row], existing[row], deep
    end
    true
  end

  def find_name_stack mode, desired, deep
    crash unless deep[:columns][:names]
    reserved = 1
    name_stacks = deep[:columns][:names][reserved..-1]
    case mode
    when :match
      return    unless name_stacks.length > 0
      name_stacks.each_with_index do |existing, i|
        found = same_heading_stack? desired, existing, deep
        return i + 1                      if found
      end
    when :insertion_point
      return -1 unless name_stacks.length > 0
      name_stacks.reverse.each_with_index do |existing, i|
        found = same_heading_stack? desired, existing, deep, :partial
        return name_stacks.length - i + 1 if found
      end
    end
    nil
  end

  def different_heading? desired, existing, deep
    r = case deep[:action]
    when "report", "show"
      !smart_heading_match?  desired, existing
    when "table"
      !strict_heading_match? desired, existing
    else
      unsupported
    end
    r
  end

  def full_reference
    "#{self.class.to_s} id #{id}: #{reference_name}"
  end

  def display_coded_heading
    h = coded_heading
    n = name ||  " - "
    c = h[:type] == "column" ?  "cell" : "aspect"
    k = (h[:kind] ?  "#{h[:kind]}" : "vague") + " #{c} #{id} [#{name}]"
    case h[:type]
    when "column"
      b = h[:mold] ? "#{h[:mold].id.to_s}" : "NO"
      bk = h[:mold].kind ? h[:kind].to_s : "vague"
      "#{k} belonging to #{bk} column "
    when "aspect"
      "#{k}"
    when "nil"
     "nil heading"
    else
      crash
    end
  end

  def coded_heading
    b = mold ? mold : self
    { :type => mold ? "column" : "aspect",
      :mold => b.recursive_kind_mold         ,
      :kind => b.recursive_kind                }
   end

  #use built-up columns
  def column_name_rows deep
    names = deep[:columns][:names]
    number_of_name_rows = (names.map {|c| c.length}).max
    names.each do |el|
      el[number_of_name_rows - 1] ||= nil
    end
    column             = -1
    name_rows  = [        ]
    names.each do |column_name|
      column += 1
      row              = -1
      column_name.each do |column_name_cell|
        name_rows[row += 1] ||= [      ]
        name_rows[row     ]     [column] = column_name_cell
      end
    end
    name_rows
  end
  #use built-up columns

  # build up columns
  def report? deep
    ["report", "show"].include? deep[:action]
  end

  def look_wider                 contexts, deep, max_aspect_depth, aspect_depth
    wider_contexts = contexts + [coded_heading]
    column             = []
    column[deep[:row]] = [self]
    if no_columns_yet? deep
      add_a_first_column(                         wider_contexts, column, deep) #if list
    elsif list
      fit_into_existing_column                                   deep, 0
    elsif column_number = find_name_stack(:match, wider_contexts        , deep)
      crash unless column_number.is_a? Integer
      fit_into_existing_column                                   deep, column_number
    else
      add_column_to_existing_ones                 wider_contexts, column, deep
    end
    unless (aspect_depth += 1) >= max_aspect_depth
      aspects.each do |aspect|
        deep = aspect.look_wider                  wider_contexts        , deep,
          max_aspect_depth, aspect_depth
      end
    end
    aspect_depth -= 1
    deep
  end
# build up columns
  def fit_into_existing_column deep, column_number
    cell_has_a_value = self.name && !self.name.strip.blank?
    row, column = deep[:row],  deep[:columns][:cells][column_number]
    if list || !report?(deep) || cell_has_a_value || !column[row]
      column[row] ||= []
      column[row]  << self
     end
  end
# build up columns
  def add_a_first_column contexts, column, deep
    deep[:columns][:cells] << column
    deep[:columns][:names] << contexts
  end
# build up columns
  def add_column_to_existing_ones name_stack, column, deep
    column_number = where_to_insert name_stack, deep
    deep[:columns][:names].insert(column_number, name_stack)
    deep[:columns][:cells].insert(column_number, column  )
  end
# build up columns
  def where_to_insert name_stack, deep
    desired = Array.new name_stack
    found = nil
    until desired.length == 0
      found = find_name_stack :insertion_point, desired, deep
      return found if found
      desired.pop
     end
    found || -1
  end
# build up columns

  def number_of_columns deep
    deep[:columns][:names].length
  end

  def nil_heading
    { :type => 'nil',
      :mold =>  nil,
      :kind => 'nil' }
  end

  def no_columns_yet? deep
    deep[:columns][:names].length == 0
  end

  def smart_heading_match? desired, existing
    if false && desired[:type] == 'column' && desired[:kind].blank?
      strict_heading_match? desired, existing
    else
      grouping_heading_match? desired, existing
    end
  end
 
  def strict_heading_match? desired, existing
    partial_heading_match?( desired, existing, :type) &&
    partial_heading_match?( desired, existing, :mold) &&
    partial_heading_match?( desired, existing, :kind)
  end
    
  def partial_heading_match? desired, existing, part
    no_e = !existing || existing[part].blank?
    no_d = !desired  || desired[ part].blank?
    return no_e ==  no_d if no_e || no_d
    existing[part] == desired[part]
  end
    
  def grouping_heading_match? desired, existing
    partial_heading_match? desired, existing, :kind
  end
 
  def self.heading_marker
    "=>" ||
    "5216731900414d06fc80654fbc27fcc88e6e9e4a"
  end

  def recursive_kind
    if r = recursive_kind_mold
      r.kind
    end
  end

  def recursive_kind_mold
    return self if kind && !kind.strip.blank?
    return self unless b = mold
    b.recursive_kind_mold
  end

  def get_mold #caching only
    @mold ||= self.class.find_by_id mold_id
  end

  def molds
    if mold
      mold.molds
    else
      []
    end + [self]
  end

  def old_recursive_mold
    if m = get_mold
      m
    elsif mold
      mold.recursive_kind
    end
  end

  def new_recursive_mold
    if m = get_mold
      m.recursive_mold
    elsif mold
      mold.recursive_kind
    end
  end

  def self.it= val
    @@it[Thread.current.object_id] = val
  end

  def self.its reference
    case       reference.class.name
    when "String"
      sub      reference
    when "Symbol"
      field    reference
    else
      nil
    end
  end

  def self.default_body
    get toy("Toy Controls")
    get its("Defaults")
    get its("Suite")
    its :body
  end

  def self.the reference
    its reference
  end

  @@it = Hash.new {|h,k| h[k] = nil }

  def self.sub reference
    case self.it.class.name
    when "Card"
      relevant = self.it.aspects.select do |aspect|
        aspect.recursive_kind ==  reference
      end + Card.find(:all  , :conditions => [
                 "list_id = ? and name         = ?" ,
               self.it.id     ,   reference
        ])
      relevant[0] if relevant.length > 0
    else
      nil
    end
  end

  def self.toy reference
    Card.find(        :first, :conditions => [
                  "owner_id = ? and name      = ?",
      User.administrator_id     ,   reference
    ])
  end

  def self.it
    @@it[Thread.current.object_id]
  end
  
  def next_slide #totlbull
    return first_item_down if first_item_down = (items || [nil])[0]
    higher_item(:list)
  end

  def previous_slide #totlbull
     return previous_item if previous_item =  lower_item(:list)
     #if parent = list
     return first_item_down if first_item_down = (items || [nil])[0]
  end
  
  def self.default_access
    "shared"
  end

  def self.default_view
    "page"
  end

  def self.blank_name
    "...."
  end

  def field x = :name
    return nil unless x && !x.blank?

  end

  def recursive_owner
    recursive_owner_context.owner
  end

  def recursive_owner_is? x
    ctx = recursive_owner_context
    ctx.owner_is? x
  end

  def recursive_owner_context
    return self                            if owner   && owner.name.strip
    return context.recursive_owner_context if context
           self
  end

  def recursive_access
    if access && access != "access"
      access
    elsif context
      context.recursive_owner
    else
      self.class.default_access
    end
  end

  def recursive_view
    if view && view != "view"
      view
    elsif context
#      logger.debug "context:#{context.to_yaml}"
      context.recursive_view
    else
      self.class.default_view
    end
  end

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
        list if list
      when whole
        whole if whole
      when table_id
        table if table
      end
  end
  
  def context_id
    list_id || whole_id || table_id
  end

#  def position
#    case
#    when whole_id; whole_position
#    when table_id; table_position
#    else         ; list_position
#    end
#  end
#
#  def position=(value)
#    attr = case
#      when whole_id; :whole_position
#      when table_id; :table_position
#      else;          :list_position
#      end
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

  def auto_view
    case self.view
    when "list", "opus", "slide", "table", "page", "report", "tree"
      self.view
    when "custom", "chart"
      "tree"
    else
      "tree"
    end
  end

  def inherit_from_mold
    return false unless example = self
    #inherit_by_example example
    true
  end

  #def look_wide
  #end

  def look_deeper               contexts, deep, max_item_depth = 9, max_aspect_depth = 9, item_depth = 0
    unless item_depth == 0
      deep = look_wider         contexts, deep, max_aspect_depth, 0
      deep[:row] += 1
    end
    deep[:indents]   ||= []
#    deep[:numberings] ||= []
    deep[:indents   ][deep[:row]] = item_depth || 0
#    deep[:numberings][deep[:row]] = self.class.numbering_list || []
    self.class.numbering_push
    unless (item_depth += 1) >= max_item_depth
      items.each do |item|
        self.class.numbering_increment
        deep = item.look_deeper contexts, deep, max_item_depth, max_aspect_depth, item_depth
      end
    end
    self.class.numbering_pop
    item_depth -= 1
    deep
  end

  def look_deep action, max_item_depth = 9, max_aspect_depth = 9
    self.class.numbering_reset
    look_deeper \
      []                                , #no context yet
      {                                   #deep
        :root                    => id,
        :row                     => 0 ,
        :columns                 => {
            :names => Array.new,
            :cells => Array.new
        }                             ,
        :action       => action       ,
        :debug_log    => ''
      }                                 ,
      max_item_depth                    ,  #optional
      max_aspect_depth                  ,  #optional
      0                                    #item_depth
  end

  def self.new_suite
    on_automatic do
      new :body   => default_body  ,
          :view   => default_view  ,
          :access => default_access
    end
  end

  def      on_automatic? thread_name = "on automatic"
    self.class.on_automatic? thread_name
  end

  def self.on_automatic? thread_name = "on automatic"
    Thread.current[thread_name]
  end

  def      on_automatic  thread_name = "on automatic", &block
    self.class.on_automatic thread_name, &block
  end

  def self.on_automatic  thread_name = "on automatic"
    raise "Must pass block to yield to" unless block_given?
    Thread.current[thread_name] = true
    yield
  ensure
    Thread.current[thread_name] = false
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

  def edit_deep
    {:origin => id}
  end

  def numeric?
    true if Float(name) rescue false
  end

  def toy_numeric?
    return false if name.blank?
    last_char   =   name.to_s[-1]
    first_char  =   name.to_s[ 0]
    toy_numeric =   name.is_a?(Numeric) ||
      (last_char  >= 48 && last_char  <= 57) ||
      (first_char >= 48 && first_char <= 57)
  end

  def blank_name
    kind.blank? ? Card.blank_name : "..." || "Empty #{kind}"
  end

  def long_reference_name
    if suite?
      "#{recursive_access} #{recursive_view} "
    else
      ""
    end + reference_name
  end

  def reference_name
    case
    when name.blank?
      blank_name
    when toy_numeric?
      "#{kind.to_s} #{name}"
    else
      name
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
    recursive_owner_is?(acting_user) || acting_user.administrator?
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

  def permitted? demand
    reason = forbidden? demand
    return !reason unless reason.is_a? String
    logger.debug "8888888888888888888888888888888888888888888888888"
    logger.debug "toy permission error"
    logger.debug "card: #{reference_name}"
    logger.debug "user: #{acting_user.name if acting_user}"
    logger.debug "owner: #{recursive_owner.name if recursive_owner}"
    logger.debug "demand #{demand.to_s}"
    logger.debug "reason #{reason.to_s}"
    seppukku
  end
  
  def forbidden? demand
#    logger.debug "Ahoy cap'n, don't shoot. I just be wantin to #{demand} #{self.reference_name}!"
    intent = case demand
      when :program
        :program
      when :manage, :delete_orphan
        :manage
      when :control_access
        :control
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
#   logger.debug "I be talkin about #{self.full_reference}"
    requirements = case inherited_access
      when "open"
        open_requirements    intent
      when "shared"
        shared_requirements  intent
      when "public"
        public_requirements  intent
      when "private"
        private_requirements intent
      when "closed"
        closed_requirements  intent
      else
        shared_requirements  intent
      end
    permission_withheld? requirements
  end

  def who
    (acting_user || Guest).name
  end

  def permission_withheld? requirements
#    logger.debug(
#      "#{who}!" +
#      "Are ye at least #{requirements} " +
#      "for owner: #{owner.name if owner}'s " +
#      "#{self.reference_name}?")
    return false if on_automatic?
    admin = acting_user.administrator?
#    logger.debug "I can see yer #{admin ? 'an' : 'not an' } administrator 9999999999999999999999999 #{acting_user.name}"
    withheld = case requirements
    when :guest
#     logger.debug "this only needs a guest"
      false
    when :signed_up
#     logger.debug "this needs a signed_up user, which #{who} #{acting_user.signed_up? ? 'is' : 'is NOT'}"
      !acting_user.signed_up?
    when :owner
#      logger.debug "You must be the owner!"
#      logger.debug "You are #{acting_user.name}."
#      logger.debug "The owner is #{recursive_owner.name}."
#      logger.debug "You #{recursive_owner_is? acting_user ? 'ARE' : 'are NOT'} the owner!"
       !recursive_owner_is?(acting_user) && !admin
    when :administrator
#      logger.debug "this needs an administrator"
      !admin
    when :no_one
      true
    else
#      logger.debug "this seems to need #{requirements}"
      requirements
    end
#    logger.debug "requirements #{requirements}" if withheld
#    logger.debug "full reference: #{full_reference}" if withheld
#    logger.debug "PERMISSION WITHHELD" if withheld
    withheld
  end

#  def acting_user_with_logging=(*args)
#    logger.debug {"==> acting_user=(#{args.inspect})"}
#    logger.debug { %Q(caller\n#{caller.join("\n")}) } unless args[0]
#    send("acting_user_without_logging=", *args)
#  end

#  alias_method_chain :acting_user=, :logging

  def open_requirements intent
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

  def closed_requirements intent
#   logger.debug "Great grand Cap'n when do I get to #{intent} the closed doc?"
    case intent
    when :program, :manage, :script
      :no_one
    when :control
      :owner
    when :design, :use
      :no_one
    when :see
      :owner
    when :initiate
      :signed_up
    else
      :no_one
    end
  end

  def tightest_requirements intent
#   logger.debug "So Cap'n can I #{intent} the private doc now?"
    case intent
    when :program, :manage
      :administrator
    when :control, :script, :design, :use, :see
      :owner
    when :initiate
      :signed_up
    else # not :program, :manage, :control, :script, :design, :use, :initiate, :see
      "unknown_intent_#{intent.to_s}_error".to_sym
    end
  end

  class << self
    alias get it=
    alias the its
  end


#  def itself
#    @itself ||= self.class.find_by_id id
#  end
#
#    def follow_up_on_create
# adadad;    if table
#      mold_existing_items_on_this_column if table.columns.length == 1 #first column
#      generate_column_cells table # new columns are inherited from in each row
#    elsif list # new row inherits from list
#      return
#      generate_row_cells # it can inherit from the columns
#      generate_columns   # it can inherit columns from a pad of its kind
#      generate_sub_items # it can inherit items   from a pad of its kind
#    end
#  end
#
#  def generate_row_cells
#    adadad;#self is a new item in a list
#    cols = list.columns
#    return false unless cols && cols.length > 0 && (first_column = cols.shift)
#    on_automatic do
#      update_attributes :mold_id => first_column.id, :kind =>first_column.kind
#      cols.each do |col|
#        this_new_aspect = self.aspects.create!(
#          :mold_id => col.id,
#          :kind        => col.kind
#        )
#        this_new_aspect.generate_aspects_recursively col
#      end
#    end
#  end
#
#  def generate_aspects_recursively source
#    adadadad; self.kind = source.kind if source.kind
#    source.aspects.each do |source_aspect|
#      sub_aspect = self.aspects.create!(
#        :mold_id => source_aspect.id,
#        :kind        => source_aspect.kind
#      )
#      sub_aspect.generate_aspects_recursively source_aspect
#    end
#  end
#
#  def inherit_from_kind
#    adadad; return unless example = find_pad
#    inherit_by_example example
#  end
#
#  def generate_columns #called directly after create
#    #self is new item in a list
#    adadad; return unless source = find_pad
#    cols = source.columns
#    return unless cols && cols.length > 0
#    self.kind ||= source.kind if source.kind
#    source.columns.each do |source_column|
#      self.columns.create!(
#        :mold_id => source_column.mold_id  ,
#        :kind        => source_column.kind
#      )
#    end
#  end
#
#  def generate_items_recursively source
#     adadad; self.kind ||= source.kind if source.kind
#     source.items.each do |source_item|
#       new_item = self.items.create!(
#          :mold_id => source_item.id  , #but this is already set to the column is it not?
#          :kind        => source_item.kind
#        )
#      new_item.generate_aspects_recursively source_item
#      new_item.generate_items_recursively   source_item
#    end
#  end
#
#  def generate_sub_items #called directly after create
#    #self is new item in its list
#    adadad; return unless example = find_pad
#    itms = example.items
#    return unless itms && itms.length > 0
#    generate_items_recursively example
#  end
#
#
#
#  def inherit_by_example example
#    adadad; return unless example
#    on_automatic do
#      generate_aspects_recursively example
#      generate_columns             example
#      generate_items_recursively   example
#    end
#  end
#
#  def inherit_dependents_from example
#    adadad; return unless example
#    on_automatic do
#      generate_dependents_recursively example
#    end
#  end
#

end
