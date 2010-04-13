require 'xml'

class NptgParser

  def initialize
  end
  
  def parse filepath
    File.open(filepath) do|infile|
      100.times do 
        (line = infile.gets)
        puts line
      end
    end
    # reader = XML::Reader.file(filepath)
    # 50.times do |time|
    #   reader.read
    #   puts "Type: #{reader.node_type}"
    #   puts "Name: #{reader.name}"
    #   puts "Value: #{reader.value}"
    # end
  end
  
  
end