require 'spec_helper'

describe Assignment do
  before(:each) do
    @valid_attributes = {
      :user_id => 1,
      :campaign_id => 1,
      :task_id => 1,
      :status_code => 0,
      :data => "value for data"
    }
  end

  it "should create a new instance given valid attributes" do
    Assignment.create!(@valid_attributes)
  end
  
  describe 'when accepting a status update' do 

     it "should update its status code" do 
       task = Assignment.new( :status_code => 0 )
       task.status = :complete
       task.status_code.should == 1
     end

   end

   describe 'when asked for its status' do 

     it 'should return the correct symbol for its status code' do 
       task = Assignment.new( :status_code => 0 )
       task.status.should == :in_progress
       task.status_code = 1
       task.status.should == :complete
     end
   end

   describe 'when asked for its status description' do 

     it 'should return the correct description for its status code' do 
       task = Assignment.new( :status_code => 0 )
       task.status_description.should == 'In Progress'
       task.status_code = 1
       task.status_description.should == 'Complete'
     end

   end
end
