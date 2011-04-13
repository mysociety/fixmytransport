# Map a numeric status_code attribute to status descriptions. Allow status to be accessed as a symbol. Example:
#
# class Task < ActiveRecord::Base
#   has_status({ 0 => 'New', 
#                1 => 'Pending', 
#                2 => 'Done'})
# end
#
# task = Task.new
# task.status = :new
#
module FixMyTransport
  module Status
  
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
  
      def has_status(status_codes)
        cattr_accessor :status_codes, :symbol_to_status_code, :status_code_to_symbol
        attr_protected :status_code
        self.status_codes = status_codes
        self.symbol_to_status_code = status_codes.inject({}) do |hash, (code, message)|
          hash[message.gsub(/ /, "").underscore.to_sym] = code
          hash
        end
        self.status_code_to_symbol = self.symbol_to_status_code.invert
        send :include, InstanceMethods
      end
    end

    module InstanceMethods

      def status
        self.status_code_to_symbol[status_code]
      end

      def status=(symbol)
        code = self.symbol_to_status_code[symbol]
        if code.nil? 
          raise "Unknown status for assignment #{symbol}"
        end
        self.status_code = code
      end

      def status_description
        status_codes[status_code]
      end
    
    end
  end
end