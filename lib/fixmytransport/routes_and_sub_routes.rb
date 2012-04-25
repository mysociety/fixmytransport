module FixMyTransport

  # Functions for routes and sub routes
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

      # as train routes are named by terminus, they have more than one name, depending on how you
      # order the terminuses - if the first_letter param is given, it specifies that terminus names
      # starting with that letter should be given first
      def name_by_terminuses(transport_mode, from_stop=nil, short=false, first_letter=nil)
        is_loop = false
        if short
          text = ""
        else
          text = MySociety::Format.ucfirst(transport_mode.name.downcase)
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
          if first_letter
            letter_terminuses, other_terminuses = self.terminuses.partition do |terminus|
              terminus.name.start_with? first_letter
            end
            terminuses = (letter_terminuses + other_terminuses).map do |terminus|
               terminus.name_without_suffix(transport_mode)
            end.uniq
          else
            terminuses = self.terminuses.map{ |terminus| terminus.name_without_suffix(transport_mode) }.uniq.sort
          end
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