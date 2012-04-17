class Guide < ActiveRecord::Base
  has_friendly_id :title, :use_slug => :true
  validates_presence_of :title, :partial_name
  has_and_belongs_to_many :problems
  has_and_belongs_to_many :campaigns
end
