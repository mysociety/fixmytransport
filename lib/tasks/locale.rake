require 'fixmytransport/data_loader'
namespace :locale do

  include FixMyTransport::DataLoader


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

  def write_line(output_file, level, key, value=nil)
    padding = []
    level.times do
      padding << "  "
    end
    padding = padding.join
    if value
      output_file.write("#{padding}#{key}: #{value.inspect}\n")
    else
      output_file.write("#{padding}#{key}:\n")
    end
  end

  def write_hash(output_file, hash, existing_hash, level, previous_key_parts)
    hash.sort.each do |key, value|
      if value.is_a?(String)
        existing_value = existing_hash[key] rescue nil
        if ! existing_value
          puts "New key: #{previous_key_parts}:#{key} #{value}" if verbose
        end
        if existing_value
          if existing_value != value
            puts "Changed value: #{previous_key_parts}:#{key} was #{existing_value} new: #{value}" if verbose
          end
          existing_hash.delete(key)
        end
        write_line(output_file, level, key, value)
      else
        write_line(output_file, level, key)
        write_hash(output_file, value, (existing_hash[key] or {}), level+1, "#{previous_key_parts}:#{key}")
        existing_hash.delete(key)
      end
    end
    existing_hash.each do |key, value|
      puts "Missing key: #{previous_key_parts}:#{key} #{value}" if verbose
    end

  end

  desc "Load model and view locale files from csv"
  task :load => :environment do
    file = check_for_param('FILE')
    csv_data = File.read(file)
    locale_values = {}
    FasterCSV.parse(csv_data, {}) do |row|
      key = row[2]
      value = row[3]
      key_hierarchy = key.split(":")
      last = key_hierarchy.pop
      current_hash = locale_values
      key_hierarchy.each do |key_element|
        current_hash[key_element] = {} if ! current_hash[key_element]
        current_hash = current_hash[key_element]
      end
      current_hash[last] = value
    end
    locale_values.sort.each do |key, data|

      if key == 'activerecord'
        models= data['errors']['models']
        models.each do |model, model_data|
          puts "writing file #{model}" if verbose
          FileUtils.mkdir_p("#{RAILS_ROOT}/data/new_locales/models/#{model}")
          output_file = File.open("#{RAILS_ROOT}/data/new_locales/models/#{model}/en.yml", 'w')
          puts model
          # get the existing locale info
          existing_file = File.open("#{RAILS_ROOT}/config/locales/models/#{model}/en.yml", 'r')
          existing_data = YAML::load(existing_file)
          existing_file.close
          write_line(output_file, 0, 'en')
          write_line(output_file, 1, 'activerecord')
          write_line(output_file, 2, 'errors')
          write_line(output_file, 3, 'models')
          write_line(output_file, 4, model)
          existing_hash = existing_data['en']['activerecord']['errors']['models'][model]
          write_hash(output_file, model_data, (existing_hash or {}), 5, "en:activerecord:errors:models:#{model}")
          output_file.close
        end

      else

        puts "writing file #{key}" if verbose
        FileUtils.mkdir_p("#{RAILS_ROOT}/data/new_locales/views/#{key}")
        output_file = File.open("#{RAILS_ROOT}/data/new_locales/views/#{key}/en.yml", 'w')

        # get the existing locale info
        existing_file = File.open("#{RAILS_ROOT}/config/locales/views/#{key}/en.yml", 'r')
        existing_data = YAML::load(existing_file)
        existing_file.close
        write_line(output_file, 0, 'en')
        write_line(output_file, 1, key)
        write_hash(output_file, data, (existing_data['en'][key] or {}), 2, key)
        output_file.close

      end

    end

  end
end