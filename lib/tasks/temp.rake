namespace :temp do

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

end
