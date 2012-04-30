class AddPersistentIdSequences < ActiveRecord::Migration

  def self.data_generation_models
    [ AdminArea,
      Route,
      District,
      JourneyPattern,
      Locality,
      Operator,
      OperatorCode,
      Region,
      RouteOperator,
      RouteSegment,
      Stop,
      StopArea,
      StopAreaMembership,
      VosaLicense ]
  end

  def self.up
    data_generation_models.each do |model_class|
      table_name = model_class.to_s.tableize
      model_class.connection.execute("CREATE SEQUENCE #{table_name}_persistent_id_seq")
    end
  end

  def self.down
    data_generation_models.each do |model_class|
      table_name = model_class.to_s.tableize
      model_class.connection.execute("DROP SEQUENCE #{table_name}_persistent_id_seq")
    end
  end
end
