class Council
  
  attr_accessor :name, :id, :emailable
  
  def initialize(attributes)
    @id = attributes[:id]
    @name = attributes[:name]
  end
  
  def self.from_hash(attributes)
    return self.new(:id => attributes['id'], 
                    :name => attributes['name'])
  end
  
  def emailable? 
    @emailable
  end

end