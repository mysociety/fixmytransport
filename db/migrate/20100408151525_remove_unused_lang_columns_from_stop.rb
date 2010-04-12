class RemoveUnusedLangColumnsFromStop < ActiveRecord::Migration
  def self.up
    remove_column :stops, :common_name_lang
    remove_column :stops, :short_common_name_lang
    remove_column :stops, :landmark_lang    
    remove_column :stops, :street_lang
    remove_column :stops, :crossing_lang
    remove_column :stops, :indicator_lang    
    remove_column :stops, :town_lang
    remove_column :stops, :suburb_lang        
  end

  def self.down
    add_column :stops, :common_name_lang, :string
    add_column :stops, :short_common_name_lang, :string
    add_column :stops, :landmark_lang, :string  
    add_column :stops, :street_lang, :string     
    add_column :stops, :crossing_lang, :string  
    add_column :stops, :indicator_lang, :string    
    add_column :stops, :town_lang, :string  
    add_column :stops, :suburb_lang, :string       
  end
end
