# Functions for stops and stop areas, both of which can be identified by a lat/lon
module FixMyTransport

  module StopsAndStopAreas

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def is_stop_or_stop_area()
        send :include, InstanceMethods
      end

    end

    module InstanceMethods
      extend ActiveSupport::Memoizable

      def responsible_organizations
        responsible = []
        # train stations are run by operators
        if transport_mode_names.include?('Train') && self.is_a?(StopArea)
          responsible = operators
        # other stops and stop areas *might* be run by operators
        elsif !self.operators.empty?
          responsible = operators
        else
          # but in general
          # if there's a PTE, they're responsible
          if passenger_transport_executive
            responsible = [ passenger_transport_executive ]
          # otherwise, the council
          else
            responsible = councils
          end
        end
        responsible
      end

      # Return a list of council objects representing the councils responsible for this location
      def councils
        council_parent_types = MySociety::VotingArea.va_council_parent_types
        # Get the council(s) covering this point
        formatted_lon = "%6.6f" % [lon]
        formatted_lat = "%6.6f" % [lat]
        council_data = MySociety::MaPit.call('point',
                                             "#{WGS_84}/#{formatted_lon},#{formatted_lat}",
                                             :type => council_parent_types)
        if [:bad_request, :service_unavailable, :not_found].include?(council_data)
          raise "Council lookup service unavailable"
        end

        council_ids = council_data.keys.map{ |council_id| council_id.to_i }

        # check councils that we know have sole responsibility for the areas they cover
        sole_responsibilities = SoleResponsibility.find(:all,
                                                        :conditions => ["council_id in (?)", council_ids])

        sole_responsibilities.each do |sole_responsibility|
          if council_ids.include?(sole_responsibility.non_responsible_council_id)
            council_data.delete(sole_responsibility.non_responsible_council_id.to_s)
          end
        end

        # Make them objects
        councils = council_data.values.map{ |council_info| Council.from_hash(council_info) }
      end
      memoize :councils

      # is the location covered by a Public Transport Executive?
      def passenger_transport_executive
        # Some Underground stations are outside Greater London
        if self.respond_to?(:area_type) && self.area_type == 'GTMU' && /Underground Station$/.match(self.name)
          return PassengerTransportExecutive.find_by_name('Transport for London')
        end
        self.councils.each do |council|
          if pte_area = PassengerTransportExecutiveArea.find_by_area_id(council.id)
            return pte_area.pte
          end
        end
        return nil
      end

      def councils_responsible?
        responsible_organizations == councils
      end

      def pte_responsible?
        responsible_organizations == [ passenger_transport_executive ]
      end

      def operators_responsible?
        responsible_organizations == operators
      end


      def name_without_suffix(transport_mode)
        if transport_mode.name == 'Train'
          return name.gsub(' Rail Station', '')
        elsif transport_mode.name == 'Tram/Metro'
          return name.gsub(' Underground Station', '')
        end
        return name
      end

      def locality_name
        locality ? locality.name : nil
      end

      def points
        [self]
      end

    end
  end

end