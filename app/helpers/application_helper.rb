# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def google_maps_key
    MySociety::Config.get('GOOGLE_MAPS_API_KEY', '')
  end
  
  def transport_mode_radio_buttons
    tags = []
    TransportMode.active.find(:all).each do |transport_mode| 
      tag = radio_button 'problem', 'transport_mode_id', transport_mode.id, {:class => 'transport-mode'}
      tag += transport_mode.name
      tags << tag
    end
    tags.join("\n")
  end
  
end
