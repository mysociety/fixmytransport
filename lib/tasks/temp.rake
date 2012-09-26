namespace :temp do

  desc 'Read incoming messages from a file and receive them into the application'
  task :receive_incoming => :environment do
    check_for_file
    file = ENV['FILE']
    text = File.open(file, 'r').read
    mail = ""
    text.each do |line|

      if /^From /.match(line)
        if !mail.blank?
          CampaignMailer.receive(mail)
          mail = ""
        end
      end
      mail += line
    end
  end


  desc "Populate non responsible council ids in existing sole responsiblity records and add new records"
  task :update_sole_responsibilities => :environment do
    # Hertfordshire County Council has sole responsibility for problems in the
    # are covered by North Hertfordshire District Council
    sr = SoleResponsibility.find(:first, :conditions => ['council_id = 2228'])
    sr.non_responsible_council_id = 2345
    sr.save!

    # Norfolk County Council has sole responsibility for all its areas
    sr = SoleResponsibility.find(:first, :conditions => ['council_id = 2233'])
    sr.non_responsible_council_id = 2389
    sr.save!

    sr = SoleResponsibility.create!(:council_id => 2233, :non_responsible_council_id => 2386)
    sr = SoleResponsibility.create!(:council_id => 2233, :non_responsible_council_id => 2387)
    sr = SoleResponsibility.create!(:council_id => 2233, :non_responsible_council_id => 2388)
    sr = SoleResponsibility.create!(:council_id => 2233, :non_responsible_council_id => 2390)
    sr = SoleResponsibility.create!(:council_id => 2233, :non_responsible_council_id => 2391)

    # Nottinghamshire County Council has sole responsibility for all District Council areas
    sr = SoleResponsibility.create!(:council_id => 2236, :non_responsible_council_id => 2410)
    sr = SoleResponsibility.create!(:council_id => 2236, :non_responsible_council_id => 2411)
    sr = SoleResponsibility.create!(:council_id => 2236, :non_responsible_council_id => 2412)
    sr = SoleResponsibility.create!(:council_id => 2236, :non_responsible_council_id => 2413)
    sr = SoleResponsibility.create!(:council_id => 2236, :non_responsible_council_id => 2414)
    sr = SoleResponsibility.create!(:council_id => 2236, :non_responsible_council_id => 2415)
    sr = SoleResponsibility.create!(:council_id => 2236, :non_responsible_council_id => 2416)

    # Dorset County Council have responsibility for several District Council areas
    sr = SoleResponsibility.create!(:council_id => 2222, :non_responsible_council_id => 2293)
    sr = SoleResponsibility.create!(:council_id => 2222, :non_responsible_council_id => 2292)
    sr = SoleResponsibility.create!(:council_id => 2222, :non_responsible_council_id => 2295)

  end

  desc 'Set a useful default for the latest_update column of problems'
  task :set_latest_update_default => :environment do

    def guess_problem_latest_update(problem)
      # If there are comments, take the date of the latest one:
      ordered_comments = problem.comments.visible.all(:order => 'created_at DESC')
      # Otherwise, if it's been confirmed, use that date, otherwise the
      # created date, or the current time:
      if ordered_comments.empty?
        problem.confirmed_at or problem.created_at or Time.now
      else
        ordered_comments[0].updated_at
      end
    end

    Problem.find(:all, :conditions => { :latest_update_at => nil }).each do |p|
      p.update_attribute('latest_update_at', guess_problem_latest_update(p))
    end

  end

end
