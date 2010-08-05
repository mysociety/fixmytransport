# A patch for ActiveResource to allow it to generate JSON with the root included (default behaviour)
# and to handle JSON with the root included when generating ActiveResource records from remote JSON
module ActiveResource
  class Base
    cattr_accessor :include_root_in_json, :instance_writer => false
    
    def encode(options={})
      case self.class.format
        when ActiveResource::Formats[:xml]
          self.class.format.encode(attributes, {:root => self.class.element_name}.merge(options))
        when ActiveResource::Formats[:json]
          if ActiveResource::Base.include_root_in_json
            self.class.format.encode({self.class.element_name => attributes}, options)
          else
            self.class.format.encode(attributes, options)
          end
        else
          self.class.format.encode(attributes, options)
      end
    end

    def load_attributes_from_response(response)
      if response['Content-Length'] != "0" && response.body.strip.size > 0
        response_data = self.class.format.decode(response.body)
        case self.class.format
          when ActiveResource::Formats[:json]
            if response_data[self.class.element_name]
              load(response_data[self.class.element_name])
            else
              load(response_data)
            end
          else
            load(response_data)
        end
      end
    end
    
    def self.instantiate_record(record, prefix_options = {})
      case format
        when ActiveResource::Formats[:json]
          if record[element_name]
            record = record[element_name]
          end
      end
      new(record).tap do |resource|
        resource.prefix_options = prefix_options
      end
    end
  
  end
end

if defined?(ActiveResource)
  # Include Active Record class name as root for JSON serialized output.
  ActiveResource::Base.include_root_in_json = true
end

