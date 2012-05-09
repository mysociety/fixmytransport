class AddPersistentIdSequences < ActiveRecord::Migration

  def self.data_generation_models
    [ AdminArea,
      District,
      JourneyPattern,
      Locality,
      Operator,
      OperatorCode,
      Region,
      Route,
      RouteOperator,
      RouteSegment,
      RouteSource,
      RouteSourceAdminArea,
      Stop,
      StopArea,
      StopOperator,
      StopAreaOperator,
      StopAreaMembership,
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
