require 'haml'

module Standardista
  module ImplicitTags
    ALLOWED_NESTING = {
      'tr' => %w(table thead tbody tfoot),
      'td' => 'tr',
      'li' => %w(ul ol),
      'col' => 'colgroup',
      'dd' => 'dl',
      'option' => %w(select optgroup),
      'span' => %w(p h1 h2 h3 h4 h5 h6 tt i b big small em strong dfn code samp kbd
        var cite abbr acronym sub sup q span bdo a dt pre caption legend address)
    }.inject(Hash.new('div')) do |mappings, pair|
      element = pair.first
      Array(pair.last).each { |parent| mappings[parent] = element }
      mappings
    end
  
    private
  
    def self.included(base)
      base.class_eval do
        alias :render_tag_without_guess :render_tag
        alias :render_tag :render_tag_with_guess
      end
    end
  
    def render_div(line)
      render_tag_with_guess('%' + allowed_nesting + line)
    end
  
    def render_tag_with_guess(line)
      if line =~ /^%([^a-z]|$)/
        line = '%' + allowed_nesting + $1 + $'
      end
      render_tag_without_guess(line)
    end
  
    def allowed_nesting
      ALLOWED_NESTING[last_element_on_stack]
    end
  
    def last_element_on_stack
      @to_close_stack.reverse_each do |pair|
        return pair.last[0] if pair.first == :element
      end
    end
  end
end

Haml::Engine.send :include, Standardista::ImplicitTags

if $0 == __FILE__
  gem 'rspec'
  require 'spec'
  
  describe Standardista::ImplicitTags do
    def allowed_nesting_for(element)
      Standardista::ImplicitTags::ALLOWED_NESTING[element]
    end
    
    def render(template)
      Haml::Engine.new(template).render
    end
    
    it "should know about nesting rules" do
      allowed_nesting_for('ul').should == 'li'
      allowed_nesting_for('dl').should == 'dd'
      allowed_nesting_for('div').should == 'div'
      allowed_nesting_for('tr').should == 'td'
    end
    
    it "should apply nesting rules while rendering" do
      template = <<-EOF
      #main
        .submain This is a nested DIV.
        %p
          .note DIV is not allowed in paragraph.

      %ul
        .first one
        .last two

      %table
        %thead
          .row
            .cell head1
            .cell head2
        .row
          .cell data1
          .cell data2
      EOF
      
      result = <<-EOF
      <div id='main'>
        <div class='submain'>This is a nested DIV.</div>
        <p>
          <span class='note'>DIV is not allowed in paragraph.</span>
        </p>
      </div>
      <ul>
        <li class='first'>one</li>
        <li class='last'>two</li>
      </ul>
      <table>
        <thead>
          <tr class='row'>
            <td class='cell'>head1</td>
            <td class='cell'>head2</td>
          </tr>
        </thead>
        <tr class='row'>
          <td class='cell'>data1</td>
          <td class='cell'>data2</td>
        </tr>
      </table>
      EOF
      
      strip_leading_indent! template
      strip_leading_indent! result
      
      render(template).should == result
    end
    
    it "should obey the 'guess' syntax" do
      template = "%ol\n  % list item"
      result = "<ol>\n  <li>list item</li>\n</ol>\n"
      
      render(template).should == result
    end
    
    it "should guess even if '%' is the only character on the line" do
      template = "%\n  Content"
      result = "<div>\n  Content\n</div>\n"
      
      render(template).should == result
    end
    
    def strip_leading_indent!(text)
      text =~ /^ +/
      if indent = $&
        text.gsub!(/(^|\n)#{indent}/, '\1')
      end
    end
  end
end