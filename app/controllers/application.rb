# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '4a0c35834d785d503aa768989f10c1e0'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
end
class Array
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

