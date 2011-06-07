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
      issues = []
      problems.each do |problem|
        if problem.visible?
          issues << problem
        elsif problem.campaign && problem.campaign.visible?
          issues << problem.campaign
        end
      end
      return issues
    end
  
  end
  
end
