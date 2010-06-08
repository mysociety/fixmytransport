module WillPaginate
  class AdminLinkRenderer < LinkRenderer
    
    private 
    
    # If the admin option is set, links point to the admin interface
    def page_link(page, text, attributes = {})
      if @options[:admin]
        url = @template.admin_url(url_for(page))
      else
        url = @template.main_url(url_for(page))
      end
      @template.link_to text, url, attributes
    end
    
  end
  
end