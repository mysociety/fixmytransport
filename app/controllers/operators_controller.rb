class OperatorsController < ApplicationController
  
  def show
    
    @operator = Operator.find(params[:id],
                              :include => [ { :route_operators => { :route => :region } }, 
                                            { :stop_areas => :locality } ])
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