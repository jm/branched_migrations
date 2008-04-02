class MigratorHelper
  def self.update_schema_version(to_version, branch)
    unless ActiveRecord::Base.connection.update("UPDATE #{ActiveRecord::Migrator.schema_info_table_name} SET version = #{to_version} WHERE branch='#{branch}'") > 0
      ActiveRecord::Base.connection.insert("INSERT INTO #{ActiveRecord::Migrator.schema_info_table_name} (version, branch) VALUES (#{to_version}, '#{branch}')") rescue nil
    end
  rescue ActiveRecord::StatementInvalid => e
    setup_schema_table
    retry
  end
  
  def self.setup_schema_table
    ActiveRecord::Base.connection.execute("ALTER TABLE #{ActiveRecord::Migrator.schema_info_table_name} ADD (branch varchar(255))")
  end
  
  def self.latest_version(directory)
    files = Dir["#{directory}/[0-9]*_*.rb"]
    
    migrations = files.inject([]) do |versions, file|
      version, name = file.scan(/([0-9]+)_([_a-z0-9]*).rb/).first

      versions << version
    end
  
    migrations.sort.last.to_i
  end
end
