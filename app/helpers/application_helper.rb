# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def google_maps_key
    MySociety::Config.get('GOOGLE_MAPS_API_KEY', '')
  end
  
  def transport_mode_radio_buttons
    tags = []
    TransportMode.find(:all).each do |transport_mode| 
      radio_button("post", "category", "rails")
      tag = radio_button 'problem', 'transport_mode_id', transport_mode.id
      tag += transport_mode.name
      tags << tag
    end
    tags.join("\n")
  end
  
end
