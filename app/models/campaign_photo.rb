class CampaignPhoto < ActiveRecord::Base
  belongs_to :campaign
  validates_attachment_presence :image
  validates_attachment_content_type :image, 
                                    :content_type => %w( image/jpeg image/png image/gif image/pjpeg image/x-png ),
                                    :message => "Please upload a .jpeg, .gif or .png image"
  
  has_attached_file :image,
                    :path => "#{MySociety::Config.get('FILE_DIRECTORY', ':rails_root/public/system')}/paperclip/:class/:attachment/:id/:style/:filename",
                    :url => "#{MySociety::Config.get('PAPERCLIP_URL_BASE', '/system/paperclip')}/:class/:attachment/:id/:style/:filename",
                    :default_url => "/images/paperclip_defaults/:class/:attachment/missing_:style.png",
                    :styles => { :default => "130x130#", :max => "600x600>" }
end