class AddPersistentIdSequences < ActiveRecord::Migration

  def self.data_generation_models
    [ AdminArea,
      District,
      JourneyPattern,
      Locality,
      LocalityLink,
      Operator,
      OperatorCode,
      PassengerTransportExecutive,
      PassengerTransportExecutiveArea,
      Region,
      Route,
      RouteLocality,
      RouteOperator,
      RouteSegment,
      RouteSource,
      RouteSourceAdminArea,
      RouteSubRoute,
      Stop,
      StopArea,
      StopAreaLink,
      StopOperator,
      StopAreaOperator,
      StopAreaMembership,
      SubRoute,
      VosaLicense ]
  end

  def self.up
    self.data_generation_models.each do |model_class|
      table_name = model_class.to_s.tableize
      model_class.connection.execute("CREATE SEQUENCE #{table_name}_persistent_id_seq")
    end
  end

  def self.down
    self.data_generation_models.each do |model_class|
      table_name = model_class.to_s.tableize
      model_class.connection.execute("DROP SEQUENCE #{table_name}_persistent_id_seq")
    end
  end
end
