# == Schema Information
# Schema version: 20100707152350
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
  exists_in_data_generation(:identity_fields => [ { :ancestor => :persistent_id },
                                                  { :descendant => :persistent_id } ],
                            :descriptor_fields => [])
  has_paper_trail :ignore => [:ancestor_id, :descendant_id, :count, :created_at, :updated_at],
                  :meta => { :replayable  => Proc.new { |instance| instance.replayable },
                             :replay_of => Proc.new { |instance| instance.replay_of } }
  diff :include => [:ancestor_id, :descendant_id]
  paper_trail_with_dag
  replayable_with_dag

end
