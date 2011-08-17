require "vendor/rails/railties/lib/rails/gem_dependency.rb"
module Rails
  class GemDependency < Gem::Dependency
  
    if method_defined?(:requirement)
      puts "got it already"
      def requirement
        req = super    
      end
    else
      puts "loading new"
      def requirement
        req = version_requirements
      end
    end
  end
end