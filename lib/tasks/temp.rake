namespace :temp do
  desc 'Update internationalization strings'
  task :update_internationalization_strings => :environment do
    Dir.glob('config/locales/**/*.yml').each do |file|
      f = File.open(file)
      lines = []
      f.each do |line|
        lines << line.gsub(/\{\{([^}]+)\}\}/, '%{\1}')
      end
      f.close
      f = File.open(file, 'w')
      lines.each do |line|
        f.write(line)
      end
      f.close
    end
  end
end
