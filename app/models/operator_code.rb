class OperatorCode < ActiveRecord::Base
  belongs_to :region
  belongs_to :operator
  
  # class methods
  
  # find any code in the region that consists of the truncated code plus one other character
  def self.find_all_by_truncated_code_and_region_id(truncated_code, region)
    code_with_wildcard = "#{truncated_code}_"
    find(:all, :conditions => ["code like ? AND region_id = ?", code_with_wildcard, region])
  end
  
end
