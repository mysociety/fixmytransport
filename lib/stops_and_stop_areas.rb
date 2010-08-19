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
      attr_accessor :responsible_organization_type
      
      def responsible_organizations
        responsible = []
        # train stations are run by operators
        if transport_mode_names.include? 'Train'
          responsible = operators
          @responsible_organization_type = :company
        # but for bus, coach, tram, metro and ferry stops
        else
          # if there's a PTE, they're responsible
          if passenger_transport_executive
            responsible = [ passenger_transport_executive ]
            @responsible_organization_type = :passenger_transport_executive
          # otherwise, the council
          else
            responsible = councils
            @responsible_organization_type = :council
          end
        end
        responsible
      end

      # Return a list of council objects representing the councils responsible for this location
      def councils
        council_parent_types = MySociety::VotingArea.va_council_parent_types
        # Get the council(s) covering this point
        council_data = MySociety::MaPit.call('point', 
                                             "#{WGS_84}/#{lon},#{lat}", 
                                             :type => council_parent_types)
        # Make them objects
        councils = council_data.values.map{ |council_info| Council.from_hash(council_info) }
        # Do we have contact information? 
        councils.each do |council|
          council_contacts = CouncilContact.find_all_by_area_id(council.id)
          if council_contacts.empty? 
            council.emailable = false
          else
            council.emailable = true
          end
        end
        councils
      end
      memoize :councils

      # is the location covered by a Public Transport Executive? 
      def passenger_transport_executive
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

      def emailable_councils
        return [] unless self.councils
        self.councils.select{ |council| council.emailable? }
      end

      def unemailable_councils
        return [] unless self.councils
        self.councils.select{ |council| ! council.emailable? }
      end

      def council_info  
        emailable_id_string = emailable_councils.map{ |council| council.id }.join(',')
        unemailable_id_string = unemailable_councils.map{ |council| council.id }.join(',')
        [emailable_id_string, unemailable_id_string].join("|")
      end
      
    end
  end
  
end