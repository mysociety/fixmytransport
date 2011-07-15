class UserMailer < ApplicationMailer

  def password_reset_instructions(user)  
    subject I18n.translate('mailers.password_reset_subject')
    from contact_from_name_and_email
    recipients user.email  
    body :edit_password_reset_url => main_url(edit_password_reset_path(user.perishable_token)), 
         :user => user
  end

  def new_account_confirmation(user, post_login_action_data, unconfirmed_model)
    subject get_subject(post_login_action_data, unconfirmed_model)
    from contact_from_name_and_email
    recipients user.email
    body :account_confirmation_url => main_url(confirm_account_path(user.perishable_token)), 
         :user => user,
         :unconfirmed_model => unconfirmed_model,
         :action => get_action_description(post_login_action_data)
  end
  
  def account_exists(user, post_login_action_data, unconfirmed_model)
    subject get_subject(post_login_action_data, unconfirmed_model)
    from contact_from_name_and_email
    recipients user.email
    body :account_confirmation_url => main_url(confirm_account_path(user.perishable_token)), 
         :user => user,
         :unconfirmed_model => unconfirmed_model,
         :action => get_action_description(post_login_action_data)
  end
  
  def already_registered(user, post_login_action_data, unconfirmed_model)
    subject get_subject(post_login_action_data, unconfirmed_model)
    from contact_from_name_and_email
    recipients user.email
    body :account_confirmation_url => main_url(confirm_account_path(user.perishable_token)), 
         :user => user,
         :unconfirmed_model => unconfirmed_model,
         :action => get_action_description(post_login_action_data)
  end
  
  private

  def supporter_confirmation_subject(campaign)
    I18n.translate('mailers.supporter_confirmation_subject', :title => campaign.title)
  end
  
  def get_action_description(post_login_action_data)
    if post_login_action_data
      case post_login_action_data[:action]
      when :join_campaign
        campaign = Campaign.find(post_login_action_data[:id])
        return I18n.translate('mailers.confirm_join_campaign', :title => campaign.title)
      when :add_comment
        return I18n.translate('mailers.confirm_comment')
      when :create_problem
        return I18n.translate('mailers.confirm_create_problem')
      end
    else
      return nil
    end
  end
  
  def get_subject(post_login_action_data, unconfirmed_model)
    if post_login_action_data
      case post_login_action_data[:action]
      when :join_campaign
        return supporter_confirmation_subject(unconfirmed_model.campaign)
      when :add_comment
        return comment_confirmation_subject(unconfirmed_model)
      when :create_problem
        return problem_confirmation_subject()
      else
        raise "Unexpected post login action #{post_login_action_data[:action]} when sending account confirmation email"
      end
    else
      return I18n.translate('mailers.account_confirmation_subject')
    end
  end
  
end