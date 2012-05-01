class AddGenerationColumnsToLocalities < ActiveRecord::Migration
  def self.up
    add_column :localities, :generation_low, :integer
    add_column :localities, :generation_high, :integer
    add_column :localities, :previous_id, :integer
    remove_index :localities, :admin_area_id
    remove_index :localities, :cached_slug
    remove_index :localities, :district_id
    execute("DROP INDEX index_localities_on_name_lower")
    remove_index :localities, :primary_metaphone
    remove_index :localities, :secondary_metaphone    
    add_index :localities, [:admin_area_id, :generation_low, :generation_high], 
                           :name => 'index_localities_on_a_and_g'
    add_index :localities, [:cached_slug, :generation_low, :generation_high],
                           :name => 'index_localities_on_cs_and_g'
    add_index :localities, [:district_id, :generation_low, :generation_high],
                          :name => 'index_localities_on_d_and_g'
    execute("CREATE INDEX index_localities_on_name_lower_and_gens 
            ON localities (lower(name), generation_low, generation_high);")
    add_index :localities, [:primary_metaphone, :generation_low, :generation_high],
                          :name => 'index_localities_on_pm_and_g' 
    add_index :localities, [:secondary_metaphone, :generation_low, :generation_high],
                                                  :name => 'index_localities_on_sm_and_g'
  end

  def self.down
    remove_index :localities, "a_and_g"
    remove_index :localities, "cs_and_g"
    remove_index :localities, "d_and_g"
    remove_index :localities, "name_lower_and_gens"
    remove_index :localities, "pm_and_g"
    remove_index :localities, "sm_and_g"
    remove_column :localities, :generation_low
    remove_column :localities, :generation_high
    remove_column :localities, :previous_id
    add_index :localities, :district_id
    add_index :localities, :admin_area_id
    add_index :localities, :cached_slug
    add_index :localities, :primary_metaphone
    add_index :localities, :secondary_metaphone
    execute "CREATE INDEX index_localities_on_name_lower ON localities ((lower(name)));"
  end
end
