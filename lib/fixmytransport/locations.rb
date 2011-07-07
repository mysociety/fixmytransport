# functions for all locations
module FixMyTransport
  
  module Locations
    def self.included(base)
      base.send :extend, ClassMethods
    end
  end
  
  module ClassMethods
    
    def is_location()
      send :include, InstanceMethods
    end
    
  end
  
  module InstanceMethods
    
    def related_issues
      issues = Problem.find_recent_issues(nil, { :location => self })
      return issues
    end
    
    def cache_description
      self.cached_description = nil
      self.cached_description = self.description
    end
  
  end
  
end
