module ActiveRecord
  class Migrator  
    def set_schema_version_after_migrating(migration)
      true
    end
  
    def current_version
      ActiveRecord::Base.connection.select_value("SELECT version FROM #{ActiveRecord::Migrator.schema_info_table_name} WHERE branch='#{@@branch}'").to_i
    end

    class << self
      def set_branch(branch)
        unless defined?(@@branch) && @@branch == branch
          puts "*" * 50
          puts "-- Executing migrations in #{branch}..."
          puts "*" * 50
          
          @@branch = branch
        end
      end

      def current_version
        ActiveRecord::Base.connection.select_value("SELECT version FROM #{ActiveRecord::Migrator.schema_info_table_name} WHERE branch='#{@@branch}'").to_i
      end
    end
  end
end