class OperatorsController < ApplicationController
  
  skip_before_filter :make_cachable
  before_filter :long_cache
  
  def show
    @operator = Operator.find(params[:id])
    @routes = Route.find(:all, :conditions => ["id in (SELECT route_id
                                                              FROM route_operators
                                                              WHERE operator_id = #{@operator.id})"],
                                      :include => :slug,
                                      :order => 'cached_description asc')
    @stations = StopArea.find(:all, :conditions => ["id in (SELECT stop_area_id 
                                                            FROM stop_area_operators
                                                            WHERE operator_id = #{@operator.id})"],
                                    :include => :slug,
                                    :order => 'name asc')
    @problems = Problem.visible.find(:all, :conditions => ["campaign_id IS NULL AND id in (SELECT problem_id 
                                                                     FROM responsibilities 
                                                                     WHERE organization_type = 'Operator'
                                                                      AND organization_id = #{@operator.id})"],
                                    :order => 'description asc')  # actually: date?
    @problem_count = @problems.size() # FIXME for now

    @campaigns = Campaign.visible.find(:all, :conditions => ["id in (SELECT campaign_id FROM problems
                                                                      WHERE problems.id in (
                                                                        SELECT problem_id 
                                                                        FROM responsibilities 
                                                                        WHERE organization_type = 'Operator'
                                                                        AND organization_id = #{@operator.id}
                                                                      ))"] ,
                                    :order => 'updated_at desc, title asc') 
    @campaign_count = @campaigns.size() # FIXME for now
    
    @route_count = Operator.connection.select_value("SELECT count(DISTINCT routes.id) AS count_routes_id 
                                                     FROM routes 
                                                     INNER JOIN route_operators 
                                                     ON routes.id = route_operators.route_id 
                                                     WHERE (route_operators.operator_id = #{@operator.id})").to_i 
    @station_count = Operator.connection.select_value("SELECT count(DISTINCT stop_areas.id) 
                                                       AS count_stop_areas_id 
                                                       FROM stop_areas
                                                       INNER JOIN stop_area_operators
                                                       ON stop_areas.id = stop_area_operators.stop_area_id 
                                                       WHERE (stop_area_operators.operator_id = #{@operator.id})").to_i 
  end

end