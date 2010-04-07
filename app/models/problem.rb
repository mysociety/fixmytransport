class Problem < ActiveRecord::Base
  validates_presence_of :subject
  validates_presence_of :description
end
