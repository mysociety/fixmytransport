namespace :guides do

  desc 'Add the static guides to common problems'
  task :add_static_guides => :environment do
    { "accessibility" => "Making your public transport accessible",
      "bus_stop_fixed" => "Getting your bus stop fixed",
      "rude_staff" => "Reporting rude transport staff",
      "discontinued_bus" => "Getting bus routes reinstated",
      "delayed_bus" => "Getting your bus to run on time",
      "overcrowding" => "Overcrowded trains, and what to do about them"
    }.each do |partial_name, title|
      g = Guide.find_by_partial_name partial_name
      if g
        g.title = title
	g.save!
      else
        Guide.create! :partial_name => partial_name, :title => title
      end
    end
  end

end
