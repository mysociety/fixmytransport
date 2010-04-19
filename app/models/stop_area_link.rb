# == Schema Information
# Schema version: 20100414172905
#
# Table name: stop_area_links
#
#  id            :integer         not null, primary key
#  ancestor_id   :integer
#  descendant_id :integer
#  direct        :boolean
#  count         :integer
#  created_at    :datetime
#  updated_at    :datetime
#

class StopAreaLink < ActiveRecord::Base
  acts_as_dag_links :node_class_name => 'StopArea'
end
