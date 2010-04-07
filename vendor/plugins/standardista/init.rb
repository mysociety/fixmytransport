if defined? Haml
  Haml::init_rails(binding) unless defined? Haml::Template

  require 'standardista'
  # require 'standardista/implicit_tags'

  config.after_initialize do
    unless :xhtml == Haml::Template::options[:format]
      require 'standardista/rails_override'
    end
  end
end
