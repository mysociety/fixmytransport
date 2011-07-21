require 'spec_helper'

describe Comment do
  before(:each) do
    @valid_attributes = {
      :user_id => 1,
      :commented_id => 1,
      :commented_type => 'CampaignUpdate',
      :text => "value for text",
      :user_name => 'A name'
    }
  end

  it "should create a new instance given valid attributes" do
    Comment.create!(@valid_attributes)
  end
  
  describe 'when adding a comment' do

    it 'should build a comment with the params passed' do
      comments = mock('comments association')
      problem = Problem.new
      problem.stub!(:comments).and_return(comments)
      mock_comment = mock_model(Comment, :save => true,
                                         :status= => nil,
                                         :confirm! => nil)
      user = mock_model(User, :name => "A Test Name")
      expected_params = { :user => user,
                          :text => 'some text',
                          :mark_fixed => true,
                          :mark_open => false }
      comments.should_receive(:build).with(expected_params).and_return(mock_comment)
      Comment.add(user, problem, "some text", mark_fixed=true, mark_open=false, comment_confirmed=true)
    end

  end
  
  describe 'when confirming' do 
  
    before do 
      @comment = Comment.new
      @comment.stub!(:save!)
      @comment.status = :new
    end
  
    describe 'if the thing being commented on is a problem' do

      before do 
        @mock_problem = mock_model(Problem, :updated_at= => true, 
                                            :save! => true,
                                            :status= => true)
        @comment.stub!(:commented).and_return(@mock_problem)
      end
          
      it 'should set the problem "updated at" attribute' do 
        @mock_problem.should_receive(:updated_at=)
        @comment.confirm!
      end
      
      it 'should save the problem' do 
        @mock_problem.should_receive(:save!)
        @comment.confirm!
      end
      
      it 'should set the problem status as fixed if appropriate' do 
        @comment.mark_fixed = true
        @mock_problem.should_receive(:status=).with(:fixed)
        @comment.confirm!
      end
      
      it 'should save the comment' do 
        @comment.should_receive(:save!)
        @comment.confirm!
      end
      
    end
    
    describe 'if the thing being commented on is a campaign' do
    
      before do 
        @mock_campaign = mock_model(Campaign, :campaign_events => mock('campaign events', :create! => true))
        @comment.stub!(:commented).and_return(@mock_campaign)
      end
      
      it 'should add a "comment_added" campaign event to the campaign' do 
        @comment.campaign_events.should_receive(:build).with(:event_type => 'comment_added', 
                                                             :described => @comment,
                                                             :campaign => @mock_campaign)
        @comment.confirm!
      end
      
      it 'should save the comment' do 
        @comment.should_receive(:save!)
        @comment.confirm!
      end
      
    end
    
  end
  
end
