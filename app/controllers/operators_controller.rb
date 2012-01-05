class OperatorsController < ApplicationController
  
  skip_before_filter :make_cachable
  before_filter :long_cache
  
  def show
    @operator = Operator.find(params[:id])
    @title = @operator.name
  
    @issues = WillPaginate::Collection.create((params[:page] or 1), 10) do |pager|
      issues = Problem.find_recent_issues(pager.per_page, {:offset => pager.offset, :single_operator => @operator})
      pager.replace(issues)
      if pager.total_entries
        @issue_count = pager.total_entries
      else
        @issue_count = Problem.visible.count(:conditions => ["id in (SELECT problem_id 
                                                               FROM responsibilities 
                                                               WHERE organization_type = 'Operator'
                                                               AND organization_id = #{@operator.id})"])                                             
        @issue_count += Campaign.visible.count(:conditions => ["id in (SELECT campaign_id FROM problems
                                                                WHERE problems.id in (
                                                                SELECT problem_id 
                                                                FROM responsibilities 
                                                                WHERE organization_type = 'Operator'
                                                                AND organization_id = #{@operator.id}))"]) 
        pager.total_entries = @issue_count
      end
    end    
   
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