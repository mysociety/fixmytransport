class QuestionnaireMailer < ApplicationMailer

  include ActionView::Helpers::DateHelper
  cattr_accessor :dryrun

  def questionnaire(issue, questionnaire, user, title)
    recipients user.name_and_email
    from contact_from_name_and_email
    subject I18n.translate('mailers.questionnaire_subject', :title => title)
    body({ :recipient => user,
           :title => title,
           :description => issue.description,
           :link => main_url(questionnaire_path(:email_token => questionnaire.token)),
           :time_ago => time_ago_in_words(issue.confirmed_at) })
  end

  def self.send_questionnaires(dryrun=false, max_questionnaires=10)
    self.dryrun = dryrun
    weeks_ago = 6
    problems = Problem.needing_questionnaire(weeks_ago)
    campaigns = Campaign.needing_questionnaire(weeks_ago)
    sent_questionnaires = 0
    (problems + campaigns).each do |issue|
      if issue.is_a?(Problem)
        user = issue.reporter
        title = issue.subject
      else
        user = issue.initiator
        title = issue.title
      end
      if !(user.suspended? || user.is_hidden?)
        if self.dryrun
          STDERR.puts("Would send the following:")
          questionnaire = issue.questionnaires.build(:user => user,
                                                     :sent_at => Time.now,
                                                     :token => 'dryruntoken')
          mail = create_questionnaire(issue, questionnaire, user, title)
          STDERR.puts(mail)
        else
          questionnaire = issue.questionnaires.create!(:user => user, :sent_at => Time.now)
          self.deliver_questionnaire(issue, questionnaire, user, title)
          sleep(0.5)
        end
        sent_questionnaires += 1

        issue.update_attribute('send_questionnaire', false)
      end
      if max_questionnaires && sent_questionnaires == max_questionnaires
        return
      end
    end

  end

end