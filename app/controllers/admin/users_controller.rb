class Admin::UsersController < Admin::AdminController
  
  def index
    @users = User.find_by_sql("SELECT users.*, comment_count 
                               FROM users, (SELECT user_id, count(*) as comment_count
                                            FROM comments 
                                            GROUP BY user_id) as comment_counts
                               WHERE users.id = comment_counts.user_id
                               ORDER by comment_count desc")
  end

end