# == Schema Information
# Schema version: 20100707152350
#
# Table name: locality_links
#
#  id            :integer         not null, primary key
#  ancestor_id   :integer
#  descendant_id :integer
#  direct        :boolean
#  count         :integer
#  created_at    :datetime
#  updated_at    :datetime
#

class LocalityLink < ActiveRecord::Base
  acts_as_dag_links :node_class_name => 'Locality'
  exists_in_data_generation()
end
