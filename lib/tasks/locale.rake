namespace :locale do 

  def iterate(hash, fhash, path, outfile)
    hash.each {|key, val|
      fhash[key] = {} unless fhash.has_key? key
      if val.is_a? Hash
        fhash[key] = {} unless fhash[key].is_a? Hash
        iterate(val, fhash[key], path+key+':', outfile)
      else
        outfile.puts "#{path}#{key}\t#{val}"
      end
    }
  end
  
  desc "Dump model and view locale files to csv"
  task :dump => :environment do 
    outfile = File.open("#{RAILS_ROOT}/data/en_strings.csv", 'w')
    Dir.glob("#{RAILS_ROOT}/config/locales/views/**/en.yml").each do |file|
      translations = YAML::load_file(file)
      en_trans = translations['en']
      iterate(en_trans, {}, '', outfile)
    end
    outfile.close()
  end
end