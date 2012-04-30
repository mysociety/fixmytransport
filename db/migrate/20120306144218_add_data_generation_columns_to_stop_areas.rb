class AddDataGenerationColumnsToStopAreas < ActiveRecord::Migration
  def self.up
    add_column :stop_areas, :generation_low, :integer
    add_column :stop_areas, :generation_high, :integer
    add_column :stop_areas, :previous_id, :integer

    remove_index :stop_areas, :cached_slug
    execute("DROP INDEX index_stop_areas_on_code_lower")
    remove_index :stop_areas, :locality_id
    execute("DROP INDEX index_stop_areas_on_name_lower")
    remove_index :stop_areas, :primary_metaphone
    remove_index :stop_areas, :secondary_metaphone

    add_index :stop_areas, [:cached_slug, :generation_low, :generation_high],
              :name => 'index_stop_areas_on_cached_slug_and_gens'

    execute("CREATE INDEX index_stop_areas_on_code_lower_and_gens
            ON stop_areas (lower(code), generation_low, generation_high);")
    add_index :stop_areas, [:locality_id, :generation_low, :generation_high]
    execute("CREATE INDEX index_stop_areas_on_name_lower_and_gens
            ON stop_areas (lower(name), generation_low, generation_high);")
    add_index :stop_areas, [:primary_metaphone, :generation_low, :generation_high]
    add_index :stop_areas, [:secondary_metaphone, :generation_low, :generation_high]
  end

  def self.down
    remove_column :stop_areas, :generation_low
    remove_column :stop_areas, :generation_high
    remove_column :stop_areas, :previous_id
    add_index :stop_areas, :cached_slug
    execute("CREATE INDEX index_stop_areas_on_code_lower
            ON stop_areas (lower(code));")
    add_index :stop_areas, :locality_id
    execute("CREATE INDEX index_stop_areas_on_name_lower
            ON stop_areas (lower(name));")
    add_index :stop_areas, :primary_metaphone
    add_index :stop_areas, :secondary_metaphone

  end
end
