namespace :temp do
  namespace 'views' do
    desc 'Renames all your rhtml views to erb'
    task 'rename' do
      Dir.glob('app/views/**/*.erb').each do |file|
        puts `git mv #{file} #{file.gsub(/\.erb$/, '.text.plain.erb')}`
      end
    end
  end
end
