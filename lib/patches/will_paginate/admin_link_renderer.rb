module WillPaginate
  class AdminLinkRenderer < LinkRenderer
    
    private 
    
    def page_link(page, text, attributes = {})
       @template.link_to text, @template.admin_url(url_for(page)), attributes
    end
    
  end
  
end