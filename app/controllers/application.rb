# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

#  include HoptoadNotifier::Catcher

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '4a0c35834d785d503aa768989f10c1e0'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password


  def prep that, part = :all
    r = {}
    r[:name         ] = part
    r[:domid        ] = dom_id   that, part
    r[:visible      ] = visible? that, part
    r[:show_hide    ] = r[:visible  ] ? 'Hide' : 'Show'
    r[:action       ] = r[:show_hide].downcase
    r[:display_style] = r[:visible  ] ? "inherit" : "none"
    r
  end

  def in_place_editor(attributes)
    click_to_edit_text = attributes.delete(:click_to_edit_text) || "..."
    blank_message = attributes.delete(:blank_message) || click_to_edit_text

    attributes = add_classes(attributes, "in-place-edit", model_id_class(this_parent, this_field))
    attributes.update(:hobo_blank_message => blank_message,
                      :click_to_edit_text => click_to_edit_text,
                      :if_blank => blank_message,
                      :no_wrapper => false)

    update = attributes.delete(:update)
    attributes[:hobo_update] = update if update
    view(attributes)
  end

#  usage
#  the_current? id, :script, :visibility , [:on, :custom]
#  the_current  id, :script, :visibility
#  the_current  id, "script   visibility"
#  set_the_current  'script   visibility',  'on'
#  set_the_current  :script, :visibility ,  :on


  def invisible? that   , part = :all
    #deprecated

  end

  def   visible? that   , part = :all
    default = case part
    when :script, :body
      'off'
    else
      'on'
    end
    the_current? that.id, part, :visibility, ['on', 'custom', 'auto'] do
      default
    end
  end

  def the_current?   *p # p: keys, followed by the val
    key = session_key p[0...-1]
    [p[-1]].flatten.include?(session[key] || yield )
  end

  def the_current    *keys
    key = session_key keys
    session[key]
  end

  def session_key         *the_keys
    w = (session_key_words the_keys).split.join '_'
    whoah unless w[0]
    w = 'c' + w if ('0'..'9').include? w[0]
    w.to_sym
  end

  def session_key_words   *the_keys
    the_keys.map{|o|
      case o.class.name
      when 'String'
        o
      when 'Array'
        o.map{|x      |                   session_key_words x    }.join ' '
      when 'Hash'
        o.map{|key,val| "#{key.to_s} is #{session_key_words val}"}.join ' AND '
      when 'String'
        o
      else
        o.to_s
      end
    }.join(' ').squeeze(" ").strip
  end

  helper_method :the_current, :the_current?, :session_key, :visible?, :invisible?, :prep

  def set_the_current *p # p: keys, followed by the val
    key          = session_key params[:id], p[0...-1]
    session[key] =                          p[    -1].to_s
  end

end

class String
  def words
    self.strip.split(/\s+/)
  end

  def first_word
    words[0]
  end

  def first_words
    words[0...-1]
  end

  def last_word
    words[-1]
  end

  def indefinite
    (self =~ /^[aeiou]/i ? "an " : "a ") + self
  end
end

class Array
  def rotate! n = 1
    n.times {push shift}
  end
  
  def dimensions
    return [0] if length == 0
    return [length] unless sub = self[0].is_a?(Array)
    [length] + sub.dimensions
  end
  def lengths
    map { |el| (self[0].is_a? Array) ? el.length : 1 }
  end
  def rectangular!
    maxi = lengths.max
    each { |el| el[maxi - 1] ||= nil } if maxi > 0
  end
  def normalize_and_transpose
    length == 0 ? [] : (Array.new rectangular!).transpose
  end
  def make_both_same_size! a
    length == 0 ? [] : (Array.new rectangular!).transpose
  end
end

