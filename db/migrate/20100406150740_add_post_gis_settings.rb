class AddPostGisSettings < ActiveRecord::Migration

  def self.up
    spatial_extensions = MySociety::Config.getbool('USE_SPATIAL_EXTENSIONS', false) 
    sql_file_path = MySociety::Config.get('SPATIAL_EXTENSION_SQL_FILE_PATH', '') 
    sql_file_name = MySociety::Config.get('SPATIAL_EXTENSION_SQL_FILE_NAME', 'postgis') 
    db_conf = ActiveRecord::Base.configurations[RAILS_ENV]
    postgres = (db_conf['adapter'] == 'postgresql')
    port = db_conf['port']
    database = db_conf['database']
    username = db_conf['username']
    if spatial_extensions and postgres
      system "createlang -p #{port} plpgsql --username=#{username} #{database}"
      system "psql -p #{port} -f #{File.join(sql_file_path, sql_file_name+'.sql')} #{database} #{username}"
      system "psql -p #{port} -f #{File.join(sql_file_path, 'spatial_ref_sys.sql')} #{database} #{username}"      
    end
  end

  def self.down
  end
end
