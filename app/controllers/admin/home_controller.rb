class Admin::HomeController < Admin::AdminController

  def index
    @routes_without_operators = Route.find_without_operators(:limit => 10)
    @routes_without_operators_total = Route.count_without_operators
    @operator_codes_without_operators = Route.find_codes_without_operators(:limit => 20)
    @operator_codes_without_operators_total = Route.count_codes_without_operators
    @assignments_needing_attention = Assignment.find_need_attention(:limit => 10)
    @assignments_needing_attention_total = Assignment.count_need_attention
    @incoming_messages_without_campaign = IncomingMessage.find(:all, :conditions => ['campaign_id is null'], :limit => 10)
    @user_count = User.registered.count()
    @user_count_this_week = User.registered.count({:conditions =>  ['created_at >= ?', (Time.now - 7.days)]})
    @comment_count = Comment.visible.count()
    @comment_count_this_week = Comment.visible.count({:conditions =>  ['created_at >= ?', (Time.now - 7.days)]})
  end
  
end
