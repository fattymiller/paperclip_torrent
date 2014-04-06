require 'rails/generators'
require "rails/generators/active_record"

module PaperclipTorrent
  class InstallGenerator < ActiveRecord::Generators::Base
    SOURCE_ROOT = File.expand_path("../../migrations", __FILE__)
    
    source_root SOURCE_ROOT
    argument :name, type: :string, default: 'random_name'
      
    def copy_migrations
      Dir.glob(File.join(SOURCE_ROOT, "*.rb")).each { |file| copy_migration File.basename(file, ".rb") }
    end

    private

    def copy_migration(filename)
      begin
        destination_filename = filename.split("_")[1..-1].join("_")
        migration_template "#{filename}.rb", "db/migrate/#{destination_filename}.rb"
      rescue
        # swallow
      end
    end
  end
end