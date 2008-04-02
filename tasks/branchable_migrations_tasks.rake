require File.dirname(__FILE__) + '/../lib/rake_extensions'

namespace :db do
  desc "BRANCHED Migrate the database through scripts in db/migrate. Target specific version with VERSION=x. Turn off output with VERBOSE=false."
  Rake::Task.redefine_task(:migrate) do
    # Do some fun monkey patching on Rake::Task.
    # TODO: Ditch this monkey patch crap and use #clean
    require File.dirname(__FILE__) + '/../lib/' + 'monkey_patches'
    
    # Stupid dependency bug thing
    Rake::Task['environment'].invoke
    
    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true

    # If a branch is specified, stich with that
    qualifier = ENV["BRANCH"] ? ENV["BRANCH"] + "/*" : "**"

    # No branch?  Run root migrations first...
    unless ENV["BRANCH"]
      ActiveRecord::Migrator.set_branch("root")
      ActiveRecord::Migrator.migrate("db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
      MigratorHelper.update_schema_version MigratorHelper.latest_version("db/migrate/"), 'root'
    end
  
    # Iterate each branch
    Dir.glob("db/migrate/#{qualifier}").each do |branch|
      # Set the proper branch name
      if ENV["BRANCH"]
        branch = ENV["BRANCH"]
      else
        next if branch =~ /.rb$/
      
        branch.gsub!(/db\/migrate\//, '')
      end
    
      # Set branch in Migrator and migrate that branch
      ActiveRecord::Migrator.set_branch(branch)
      ActiveRecord::Migrator.migrate("db/migrate/#{branch}/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
      
      # Update the schema version our way!
      # TODO: Use the @@branch in Migrator to let Migrator do this on its own
      MigratorHelper.update_schema_version MigratorHelper.latest_version("db/migrate/#{branch}/"), branch
    end
  
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end
end