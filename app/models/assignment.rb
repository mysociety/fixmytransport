class Assignment < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :user
  serialize :data
  STATUS_CODES = { 0 => 'In Progress', 
                   1 => 'Complete' }
  
  SYMBOL_TO_STATUS_CODE = STATUS_CODES.inject({}) do |hash, (code, message)|
    hash[message.gsub(/ /, "").underscore.to_sym] = code
    hash
  end
  
  STATUS_CODE_TO_SYMBOL = SYMBOL_TO_STATUS_CODE.invert
  
  def status
    STATUS_CODE_TO_SYMBOL[status_code]
  end
  
  def status=(symbol)
    code = SYMBOL_TO_STATUS_CODE[symbol]
    if code.nil? 
      raise "Unknown status for task #{symbol}"
    end
    self.status_code = code
  end
  
  def status_description
    STATUS_CODES[status_code]
  end
  
end
