module FixMyTransport

  # Common functions for all transport locations - stops, stop areas and routes
  module Locations

    attr_accessor :highlighted

    def self.included(base)
      base.send :extend, ClassMethods
    end
  end

  module ClassMethods

    def is_location()
      send :include, InstanceMethods
    end

    def statuses
      { 'ACT' => 'Active',
        'DEL' => 'Deleted',
        'PEN' => 'Pending' }
    end

  end

  module InstanceMethods

    def campaigns
      @campaigns = get_campaigns() unless defined? @campaigns
      @campaigns
    end

    def visible_campaigns
      @visible_campaigns = get_campaigns(only_visible=true) unless defined? @visible_campaigns
      @visible_campaigns
    end

    def get_campaigns(only_visible=false)
      conditions = [ "location_type = '#{self.class.base_class.name.to_s}'
                      AND location_persistent_id = ?", self.persistent_id ]
      if only_visible
        puts "looking for only visible"
        Campaign.visible.find(:all, :conditions => conditions,
                                    :order => 'created_at desc')
      else
        Campaign.find(:all, :conditions => conditions,
                            :order => 'created_at desc')
      end
    end

    def problems
      @problems = get_problems() unless defined? @problems
      @problems
    end

    def visible_problems
      @visible_problems = get_problems(only_visible=true) unless defined? @visible_problems
      @visible_problems
    end

    # Note use of scope to constrain search to visible problems - the scope includes
    # a clause excluding problems with campaigns.
    def get_problems(only_visible=false)
      conditions = ["location_type = '#{self.class.base_class.name.to_s}'
                     AND location_persistent_id = ?", self.persistent_id ]
      if only_visible
        Problem.visible.find(:all, :conditions => conditions,
                                   :order => 'created_at desc')
      else
        Problem.find(:all, :conditions => conditions,
                                   :order => 'created_at desc')
      end
    end

    # can include issues at related locations
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
