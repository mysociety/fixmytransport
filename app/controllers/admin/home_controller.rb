class Admin::HomeController < Admin::AdminController

  def index
    @routes_without_operators = Route.find_without_operators(:limit => 20)
    @routes_without_operators_total = Route.count_without_operators
    @operator_codes_without_operators = Route.find_codes_without_operators(:limit => 20)
    @operator_codes_without_operators_total = Route.count_codes_without_operators
  end
  
end
