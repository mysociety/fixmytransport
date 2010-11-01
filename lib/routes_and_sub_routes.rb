# Functions for routes and sub routes
module FixMyTransport
  
  module RoutesAndSubRoutes
    
    def self.included(base)
      base.send :extend, ClassMethods
    end
    
    module ClassMethods
      
      def is_route_or_sub_route()
        send :include, InstanceMethods
      end
      
    end

    module InstanceMethods
      
      def name_by_terminuses(transport_mode, from_stop=nil, short=false)
        is_loop = false
        if short
          text = ""
        else
          text = transport_mode.name.downcase
        end
        if from_stop
          if terminuses.size > 1
            terminuses = self.terminuses.reject{ |terminus| terminus == from_stop }
          else
            is_loop = true
            terminuses = self.terminuses
          end
          terminuses = terminuses.map{ |terminus| terminus.name_without_suffix(transport_mode) }.uniq
          if terminuses.size == 1
            if is_loop
              text += " towards #{terminuses.to_sentence}"
            else
              text += " towards #{terminuses.to_sentence}"
            end
          else
            text += " between #{terminuses.sort.to_sentence}"
          end
        else
          terminuses = self.terminuses.map{ |terminus| terminus.name_without_suffix(transport_mode) }.uniq
          if terminuses.size == 1
            text += " from #{terminuses.to_sentence}"
          else
            if short
              text += "#{terminuses.join(' to ')}"     
            else
              text += " route between #{terminuses.to_sentence}"     
            end
          end
        end 
        text
      end
    end
  
  end
  
end